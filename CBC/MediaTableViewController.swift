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
        if scrollView.contentOffset.y < -100 { //change 100 to whatever you want
            if !Globals.shared.isRefreshing {
                refreshControl?.beginRefreshing()
                if let refreshControl = refreshControl {
                    handleRefresh(refreshControl)
                }
            }
        } else if scrollView.contentOffset.y >= 0 {
            
        }
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBar:textDidChange", completion: nil)
            return
        }
        let searchText = searchText.uppercased()
        
        Globals.shared.search.text = searchText
        
        if (searchText != Constants.EMPTY_STRING) { //
            updateSearchResults(searchText,completion: nil)
        } else {
            display.clear()
            
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

        searchBar.resignFirstResponder()

        let searchText = searchBar.text?.uppercased()
        
        Globals.shared.search.text = searchText
        
        if Globals.shared.search.valid {
            updateSearchResults(searchBar.text,completion: nil)
        } else {
            display.clear()
            
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
        
        return !Globals.shared.isLoading && !Globals.shared.isRefreshing && (Globals.shared.media.all != nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        Globals.shared.search.active = true
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidBeginEditing", completion: nil)
            return
        }
        
        searchBar.showsCancelButton = true
        
        let searchText = searchBar.text?.uppercased()
        
        Globals.shared.search.text = searchText
        
        if Globals.shared.search.valid { //
            updateSearchResults(searchText,completion: nil)
        } else {
            display.clear()
            
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
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        Globals.shared.search.active = false
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarCancelButtonClicked", completion: nil)
            return
        }
        
        didDismissSearch()
    }
    
    func didDismissSearch()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:didDismissSearch", completion: nil)
            return
        }
        
        Globals.shared.search.text = nil
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        disableBarButtons()
        
        display.clear()
        
        tableView?.reloadData()
        
        startAnimating()
        
        display.setup(Globals.shared.media.active)
        
        tableView?.reloadData()
        
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

//extension MediaTableViewController : PopoverPickerControllerDelegate
//{
//    // MARK: PopoverPickerControllerDelegate
//    
//    func stringPicked(_ string:String?, purpose:PopoverPurpose?)
//    {
//        Thread.onMainThread {
//            self.dismiss(animated: true, completion: {
//                self.presentingVC = nil
//            })
//        }
//        
//        guard (Globals.shared.mediaCategory.selected != string) || (Globals.shared.mediaRepository.list == nil) else {
//            return
//        }
//        
//        Globals.shared.mediaCategory.selected = string
//        
////        Globals.shared.mediaPlayer.unobserve()
////
////        if Globals.shared.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) {
////            Globals.shared.mediaPlayer.pause()
////        }
////
////        Globals.shared.cancelAllDownloads()
//        display.clear()
//        
//        Thread.onMainThread {
//            self.tableView?.reloadData()
//            
//            self.tableView?.isHidden = true
//            if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
//                self.logo.isHidden = true // Don't like it offset, just hide it for now
//            }
//
////            if self.splitViewController?.viewControllers.count > 1 {
////                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
////            }
//        }
//        
//        tagLabel.text = nil
//        
//        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
////        Globals.shared.media = Media()
////
////        loadMediaItems()
////        {
////            self.loadCompletion()
////        }
//    }
//}

extension MediaTableViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
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
            actions.append(AlertAction(title: Constants.Strings.Delete, style: .destructive) {
                let alert = UIAlertController(  title: "Confirm Removal From VoiceBase",
                                                message: title,
                    preferredStyle: .alert)
                
                alert.makeOpaque()
                
                let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
                    (action : UIAlertAction!) -> Void in
                    VoiceBase.delete(mediaID: mediaID)
                    
                    searchIndex?[key]?.remove(at: indexPath.row)
                    
                    if searchIndex?[key]?.count == 0 {
                        searchIndex?[key] = nil
                    }

                    if searchIndex != self.stringIndex, let keys = self.stringIndex?.keys?.sorted() {
                        for key in keys {
                            if let values = self.stringIndex?[key] {
                                var count = 0
                                
                                for value in values {
                                    if (value["mediaId"] as? String) == mediaID {
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

                    popover.section.stringIndex = searchIndex?.stringIndex(key: "title", sort: nil) //.keys.count > 0 ? stringIndex : nil
                    
                    popover.updateToolbar()
                    
                    Thread.onMainThread {
                        popover.tableView?.isEditing = false
                        popover.tableView?.reloadData()
                        popover.tableView?.reloadData()
                    }
                })
                alert.addAction(yesAction)
                
                let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(noAction)
                
                self.present(alert, animated: true, completion: nil)
            })
            
            actions.append(AlertAction(title: "Media ID", style: .default) {
                let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                message: title,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                alert.addTextField(configurationHandler: { (textField:UITextField) in
                    textField.text = mediaID
                })
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction) -> Void in
                })
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
            })
            
            actions.append(AlertAction(title: "Information", style: .default) {
                self.popover?.activityIndicator.isHidden = false
                self.popover?.activityIndicator.startAnimating()
                
                VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                    if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? WebViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        popover.navigationItem.title = "Information" // self?.popover?.navigationItem.title // "VoiceBase Media Item"
                        
                        popover.html.fontSize = 12
                        popover.html.string = insertHead(VoiceBase.html(json),fontSize: popover.html.fontSize)
                        
                        popover.search = true
                        popover.content = .html
                        
                        Thread.onMainThread {
                            self?.popover?.activityIndicator.stopAnimating()
                            self?.popover?.activityIndicator.isHidden = true
                            
                            self?.popover?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                    }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                        self?.popover?.activityIndicator.stopAnimating()
                        self?.popover?.activityIndicator.isHidden = true
                        
                        Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                })
            })
            
            actions.append(AlertAction(title: "Inspector", style: .default) {
                self.popover?.activityIndicator.isHidden = false
                self.popover?.activityIndicator.startAnimating()
                
                VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                    print(json as Any)
                    if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        popover.search = true
                        popover.stringsAny = json
                        popover.purpose = .showingVoiceBaseMediaItem
                        popover.navigationItem.title = "Inspector"
                        
                        Thread.onMainThread {
                            self?.popover?.activityIndicator.stopAnimating()
                            self?.popover?.activityIndicator.isHidden = true
                            
                            // Present works reliably for subsequent pushes. Push DOES NOT I HAVE NO IDEA WHY
                            self?.popover?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                    }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                        self?.popover?.activityIndicator.stopAnimating()
                        self?.popover?.activityIndicator.isHidden = true
                        
                        Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                })
            })
        }

        if let mediaID = value["mediaId"] as? String {
            if let mediaList = Globals.shared.media.all?.list {
                let mediaItems = mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                        return transcript.mediaID == mediaID
                    }).count == 1
                })
                if mediaItems.count == 1, let mediaItem = mediaItems.first {
                    actions.append(AlertAction(title: "Locate", style: .default) {
                        self.dismiss(animated: true, completion: nil)
                        self.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    })
                } else {
                    
                }
            }
        }
        
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
                    
                    guard let mediaID = value["mediaId"] as? String else {
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
                    
                    if Globals.shared.media.all?.list?.filter({ (mediaItem:MediaItem) -> Bool in
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

                if let mediaID = value?["mediaId"] as? String,let title = value?["title"] as? String {
                    var actions = [AlertAction]()

                    actions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                        let alert = UIAlertController(  title: "Confirm Removal From VoiceBase",
                                                        message: title,
                            preferredStyle: .alert)
                        
                        alert.makeOpaque()

                        let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
                            (action : UIAlertAction) -> Void in
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
                                            if let string = value["title"] as? String {
                                                strings.append(string)
                                            }
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

                            self.popover?.section.counts = counts.count > 0 ? counts : nil
                            self.popover?.section.indexes = indexes.count > 0 ? indexes : nil

                            self.popover?.updateToolbar()
                            
                            self.popover?.tableView?.isEditing = false
                            
                            self.popover?.tableView?.reloadData()
                            self.popover?.tableView?.reloadData()
                        })
                        alert.addAction(yesAction)

                        let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction) -> Void in

                        })
                        alert.addAction(noAction)

                        self.present(alert, animated: true, completion: nil)
                    }))

                    actions.append(AlertAction(title: "Media ID", style: .default, handler: {
                        let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                        message: title,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()

                        alert.addTextField(configurationHandler: { (textField:UITextField) in
                            textField.text = mediaID
                        })

                        let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction) -> Void in
                        })
                        alert.addAction(okayAction)

                        self.present(alert, animated: true, completion: nil)
                    }))

                    self.popover?.activityIndicator.isHidden = false
                    self.popover?.activityIndicator.startAnimating()
                    
                    actions.append(AlertAction(title: "Details", style: .default, handler: {
                        VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                            if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                                let popover = navigationController.viewControllers[0] as? WebViewController {
                                
                                popover.html.fontSize = 12
                                popover.html.string = insertHead(VoiceBase.html(json),fontSize: popover.html.fontSize)
                                
                                popover.search = true
                                popover.content = .html
                                
                                Thread.onMainThread {
                                    self?.popover?.activityIndicator.stopAnimating()
                                    self?.popover?.activityIndicator.isHidden = true
                                    
                                    popover.navigationItem.title = "VoiceBase Media Item"
                                    self?.popover?.navigationController?.pushViewController(popover, animated: true)
                                }
                            }
                            }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                                self?.popover?.activityIndicator.stopAnimating()
                                self?.popover?.activityIndicator.isHidden = true
                                
                                Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                        })
                    }))
                    
                    actions.append(AlertAction(title: "Inspector", style: .default, handler: {
                        self.popover?.activityIndicator.isHidden = false
                        self.popover?.activityIndicator.startAnimating()
                        
                        VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                            if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                                popover.search = true
                                popover.stringsAny = json
                                popover.purpose = .showingVoiceBaseMediaItem
                                
                                Thread.onMainThread {
                                    self?.popover?.activityIndicator.stopAnimating()
                                    self?.popover?.activityIndicator.isHidden = true
                                    
                                    popover.navigationItem.title = "VoiceBase Media Item"
                                    self?.popover?.navigationController?.pushViewController(popover, animated: true)
                                }
                            }
                            }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                                self?.popover?.activityIndicator.stopAnimating()
                                self?.popover?.activityIndicator.isHidden = true
                                
                                Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                        })
                    }))

                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))

                    Alerts.shared.alert(title:"VoiceBase Media Item\nNot in Use", message:nil, actions:actions)
                }
            }
        }
    }
    
    @objc func historyActions()
    {
        let alert = UIAlertController(title: "Delete History?",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.makeOpaque()
        
        let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: .destructive, handler: { (alert:UIAlertAction!) -> Void in
            Globals.shared.history = nil
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: Constants.SETTINGS.HISTORY)
            defaults.synchronize()
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(yesAction)

        let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (alert:UIAlertAction!) -> Void in

        })
        alert.addAction(cancelAction)
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func done()
    {
        dismiss(animated: true, completion: nil)
    }
    

    func showMenu(action:String?,mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:showMenu", completion: nil)
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
                if let contains = Globals.shared.media.active?.mediaItems?.contains(mediaItem), contains {
                    if tableView.isEditing {
                        tableView.setEditing(false, animated: true)
                        DispatchQueue.global(qos: .background).async { [weak self] in
                            Thread.sleep(forTimeInterval: 0.1)
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    } else {
                        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                    }
                } else {
                    if let text = mediaItem.text, let contextTitle = Globals.shared.contextTitle {
                        alert(viewController:self,title: "Not in List",message: "\"\(text)\"\nis not in the list \"\(contextTitle).\"  Show \"All\" and try again.",completion:nil)
                    }
                }
            } else {
                alert(viewController:self,title: "Media Item Not Found!",message: "Oops, this should never happen!",completion:nil)
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
                alert(viewController:self,title:"No Scripture Index Available",message: "The Scripture references for these media items are not specific.",completion:nil)
            } else {
                performSegue(withIdentifier: Constants.SEGUE.SHOW_SCRIPTURE_INDEX, sender: nil)
            }
            break
            
        case Constants.Strings.Lexicon_Index:
            guard (Globals.shared.media.active?.lexicon?.eligible != nil) else {
                alert(viewController:self,title:"No Lexicon Index Available",
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
                
                popover.stringsFunction = { ()->[String]? in
                    let strings = Globals.shared.relevantHistoryList

                    Thread.onMainThread {
                        popover.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Delete All", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.historyActions))
                        popover.navigationItem.leftBarButtonItem?.isEnabled = strings?.count > 0
                    }
                    
                    return strings
                }
                
                present(navigationController, animated: true, completion: {
                    self.presentingVC = navigationController
                })
            }
            break
            
        case Constants.Strings.Live:
            guard   Globals.shared.mediaStream.streamEntries?.count > 0, Globals.shared.reachability.isReachable,
                    let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController else {
                break
            }
            
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = self
            
            popover.navigationItem.title = Constants.Strings.Live_Events
            
            popover.allowsSelection = true
            
            // An enhancement to selectively highlight (select)
            popover.shouldSelect = { (indexPath:IndexPath) -> Bool in
                if let keys = popover.section.stringIndex?.keys {
                    let sortedKeys = [String](keys).sorted()
                    return sortedKeys[indexPath.section] == Constants.Strings.Playing
                }

                return false
            }

            // An alternative to rowClickedAt
            popover.didSelect = { (indexPath:IndexPath) -> Void in
                if let keys = popover.section.stringIndex?.keys {
                    let sortedKeys = [String](keys).sorted()
                    
                    let key = sortedKeys[indexPath.section]
                    
                    if key == Constants.Strings.Playing {
                        self.dismiss(animated: true, completion: nil)
                        
                        if let streamEntry = StreamEntry(Globals.shared.mediaStream.streamEntryIndex?[key]?[indexPath.row]) {
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
                    
                    popover.section.stringIndex = Globals.shared.mediaStream.streamStringIndex
                    
                    popover.tableView.reloadData()
                }
            }
            
            // Makes no sense w/o section.showIndex also being true - UNLESS you're using section.stringIndex
            popover.section.showHeaders = true
            
            present(navigationController, animated: true, completion: {
                // This is an alternative to popover.stringsFunction
                popover.activityIndicator.isHidden = false
                popover.activityIndicator.startAnimating()
                
                self.loadLive() {
                    popover.section.stringIndex = Globals.shared.mediaStream.streamStringIndex
                    popover.tableView.reloadData()
                    
                    popover.activityIndicator.stopAnimating()
                    popover.activityIndicator.isHidden = true
                }

                self.presentingVC = navigationController
            })
            break
            
        case Constants.Strings.Settings:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SETTINGS_NAVCON) as? UINavigationController,
                let _ = navigationController.viewControllers[0] as? SettingsViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = self

                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = showButton
                
                present(navigationController, animated: true, completion: {
                    self.presentingVC = navigationController
                })
            }
            break
            
        case Constants.Strings.VoiceBase_API_Key:
            let alert = UIAlertController(  title: Constants.Strings.VoiceBase_API_Key,
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            alert.addTextField(configurationHandler: { (textField:UITextField) in
                textField.text = Globals.shared.voiceBaseAPIKey
            })
            
            let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction) -> Void in
                Globals.shared.voiceBaseAPIKey = alert.textFields?[0].text
            })
            alert.addAction(okayAction)

            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                (action : UIAlertAction) -> Void in
            })
            alert.addAction(cancel)
            
            present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.VoiceBase_Media:
            guard Globals.shared.reachability.isReachable else {
                Alerts.shared.alert(title:"Network Error",message:"VoiceBase media not available.")
                return
            }
            
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self

                self.popover = navigationController.viewControllers[0] as? PopoverTableViewController
                
                self.popover?.sectionBarButtons = true
                
                self.popover?.navigationItem.title = Constants.Strings.VoiceBase_Media
                
                self.popover?.refresh = {
                    self.popover?.navigationController?.isToolbarHidden = true

                    self.popover?.section.strings = nil
                    self.popover?.section.headerStrings = nil
                    self.popover?.section.counts = nil
                    self.popover?.section.indexes = nil
                    
                    self.popover?.tableView?.reloadData()
                    
                    VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        self.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                            if  let date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                                let date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                                return Date(string: date0) < Date(string: date1)
                            } else {
                                return false // arbitrary
                            }
                        })
                        
                        self.popover?.section.stringIndex = self.stringIndex?.stringIndex(key: "title", sort: nil)

                        Thread.onMainThread {
                            self.popover?.updateSearchResults()
                            
                            self.popover?.updateToolbar()
                            
                            self.popover?.tableView?.reloadData()
                            
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
                        }
                    },onError: nil)
                }
                
                self.popover?.editActionsAtIndexPath = self.rowActions
                
                self.popover?.delegate = self
                self.popover?.purpose = .showingVoiceBaseMediaItems
                self.popover?.allowsSelection = false
                
                self.popover?.section.showHeaders = true
                
                self.popover?.search = true
                
                self.present(navigationController, animated: true, completion: {
                    self.popover?.activityIndicator.startAnimating()
                    
                    VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        self.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                            if  let date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                                let date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                                return Date(string: date0) < Date(string: date1)
                            } else {
                                return false // arbitrary
                            }
                        })
                        
                        self.popover?.section.stringIndex = self.stringIndex?.stringIndex(key: "title", sort: nil)
                        
                        self.popover?.updateToolbar()
                        
                        self.popover?.updateSearchResults()

                        Thread.onMainThread {
                            self.popover?.tableView?.reloadData()
                            self.popover?.activityIndicator.stopAnimating()
                        }
                    },onError: nil)
                    
                    self.presentingVC = navigationController
                })
            }
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
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingCategory:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            guard (Globals.shared.mediaCategory.selected != string) || (Globals.shared.mediaRepository.list == nil) else {
                return
            }
            
            Globals.shared.mediaCategory.selected = string
            
            self.display.clear()
            
            Thread.onMainThread {
                self.mediaCategoryButton.setTitle(Globals.shared.mediaCategory.selected)
                self.tagLabel.text = nil
                self.tableView?.reloadData()
            }

            process(viewController: self, disableEnable: true, hideSubviews: false, work: { () -> (Any?) in
                self.selectedMediaItem = Globals.shared.selectedMediaItem.master
                
                Globals.shared.media.all = MediaListGroupSort(mediaItems: Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                    mediaItem.category == Globals.shared.mediaCategory.selected
                }))

                Globals.shared.media.tagged.clear()

                if let tag = Globals.shared.media.tags.selected {
                    Globals.shared.media.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes])
                }

                self.display.setup(Globals.shared.media.active)
                
                return nil
            }) { (data:Any?) in
                self.updateUI()
                Thread.onMainThread {
                    self.tableView?.reloadData()
                    
                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: .top)
                    
                    // Need to update the MVC cells.
                    if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
                    }
                }
            }

//            Globals.shared.mediaPlayer.unobserve()
//
//            Globals.shared.mediaPlayer.pause()
//
//            Globals.shared.cancelAllDownloads()
//            display.clear()
//
//            Thread.onMainThread {
//                self.tableView?.reloadData()
//
//                self.tableView?.isHidden = true
//                if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
//                    self.logo.isHidden = true // Don't like it offset, just hide it for now
//                }
//
//                if self.splitViewController?.viewControllers.count > 1 {
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
//                }
//            }
//
//            tagLabel.text = nil
//
//            // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
//            Globals.shared.media = Media()
//
//            loadMediaItems()
//            {
//                self.loadCompletion()
//            }
            break
            
        case .selectingCellSearch:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            var searchText = strings[index].uppercased()
            
            if let range = searchText.range(of: " (") {
                searchText = String(searchText[..<range.lowerBound])
            }
            
            Globals.shared.search.active = true
            Globals.shared.search.text = searchText
            
            tableView?.setEditing(false, animated: true)
            searchBar.text = searchText
            searchBar.showsCancelButton = true
            
            updateSearchResults(searchText,completion: nil)
            break
            
        case .selectingCellAction:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
                }
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
            
        case .selectingLexicon: // No longer in use.  Replaced by .selectingCellSearch
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            _ = navigationController?.popViewController(animated: true)
            
            if let range = string.range(of: " (") {
                let searchText = String(string[..<range.lowerBound]).uppercased()
                
                Globals.shared.search.active = true
                Globals.shared.search.text = searchText
                
                Thread.onMainThread {
                    self.searchBar.text = searchText
                    self.searchBar.showsCancelButton = true
                }
                
                // Show the results directly rather than by executing a search
                if let list:[MediaItem]? = Globals.shared.media.toSearch?.lexicon?.words?[searchText]?.map({ (mediaItemFrequency:(key: MediaItem,value: Int)) -> MediaItem in
                    return mediaItemFrequency.key
                }) {
                    updateSearches(searchText:searchText,mediaItems: list)
                    updateDisplay(searchText:searchText)
                }
            }
            break
            
        case .selectingHistory:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            if let history = Globals.shared.relevantHistory {
                var mediaItemID:String
                
                if let range = history[index].range(of: Constants.TAGS_SEPARATOR) {
                    mediaItemID = String(history[index][range.upperBound...])
                } else {
                    mediaItemID = history[index]
                }
                
                if let mediaItem = Globals.shared.mediaRepository.index?[mediaItemID] {
                    if mediaItem.text != strings[index] {
                        if let text = mediaItem.text {
                            print(text,strings[index])
                        }
                    }
                    
                    if let contains = Globals.shared.media.active?.mediaItems?.contains(mediaItem), contains {
                        selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                    } else {
                        if let text = mediaItem.text, let contextTitle = Globals.shared.contextTitle {
                            alert(  viewController:self,
                                    title:"Not in List",
                                    message: "\"\(text)\"\nis not in the list \"\(contextTitle).\"  Show \"All\" and try again.",
                                completion:nil)
                        }
                    }
                } else {
                    alert(viewController:self,title:"Media Item Not Found!",
                          message: "Oops, this should never happen!",
                          completion:nil)
                }
            }
            break
            
        case .selectingTags:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            // Should we be showing Globals.shared.media.active?.mediaItemTags instead?  That would be the equivalent of drilling down.
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            if (index < 0) || (index >= strings.count) {
                print("Index out of range")
            }
            
            process(viewController: self, disableEnable: true, hideSubviews: false, work: { () -> (Any?) in
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
                    
                    let tagSelected = strings[index]
                    
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
                    Thread.onMainThread {
                        self?.display.clear()
                        
                        self?.tableView?.reloadData()
                        
                        self?.startAnimating()
                        
                        self?.disableBarButtons()
                    }
                    
                    if (Globals.shared.search.active) {
                        self?.updateSearchResults(Globals.shared.search.text,completion: nil)
                    }
                    
                    Thread.onMainThread {
                        self?.display.setup(Globals.shared.media.active)
                        
                        self?.tableView?.reloadData()
                        self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self?.stopAnimating()
                        
                        self?.enableBarButtons()
                        self?.setupActionAndTagsButton()
                        self?.setupTag()
                    }
                }
            }
            break
            
        case .selectingSection:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            if let section = Globals.shared.media.active?.section?.headerStrings?.index(of: strings[index]) {
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
                tableView?.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            }
            break
            
        case .selectingGrouping:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            Globals.shared.grouping = Globals.shared.groupings[index]
            
            if Globals.shared.media.need.grouping {
                display.clear()
                
                tableView?.reloadData()
                
                startAnimating()
                
                disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.display.setup(Globals.shared.media.active)
                    
                    Thread.onMainThread {
                        self?.tableView?.reloadData()
                        
                        self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self?.stopAnimating()
                        
                        self?.enableBarButtons()
                    }
                }
            }
            break
            
        case .selectingSorting:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            Globals.shared.sorting = Constants.sortings[index]
            
            if (Globals.shared.media.need.sorting) {
                display.clear()
                
                Thread.onMainThread {
                    self.tableView?.reloadData()
                    
                    self.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        self?.display.setup(Globals.shared.media.active)
                        
                        Thread.onMainThread {
                            self?.tableView?.reloadData()
                            
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
                            self?.stopAnimating()
                            
                            self?.enableBarButtons()
                        }
                    }
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
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            switch string {
            case Constants.Strings.View_List:
                if let string = Globals.shared.media.active?.html?.string {
                    presentHTMLModal(viewController: self, mediaItem: nil, style: .overFullScreen, title: Globals.shared.contextTitle, htmlString: string)
                } else {
                    process(viewController: self, work: { [weak self] () -> (Any?) in
                        if Globals.shared.media.active?.html?.string == nil {
                            Globals.shared.media.active?.html?.string = setupMediaItemsHTMLGlobal(includeURLs:true, includeColumns:true)
                        }
                        return Globals.shared.media.active?.html?.string
                    }, completion: { [weak self] (data:Any?) in
                        if let vc = self {
                            presentHTMLModal(viewController: vc, mediaItem: nil, style: .overFullScreen, title: Globals.shared.contextTitle, htmlString: data as? String)
                        }
                    })
                }
                break

            default:
                break
            }
            break
            
        case .selectingTimingIndexWord:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = string
                popover.wholeWordsOnly = true
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = {
                    guard let times = popover.transcript?.transcriptSegmentTokenTimes(token: string), let transcriptSegmentComponents = popover.transcript?.transcriptSegmentComponents else {
                        return nil
                    }
                    
                    var strings = [String]()
                    
                    for time in times {
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            if transcriptSegmentComponent.contains(time+" --> ") { //
                                var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                                
                                if transcriptSegmentArray.count > 2  {
                                    let count = transcriptSegmentArray.removeFirst()
                                    let timeWindow = transcriptSegmentArray.removeFirst()
                                    let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") // 
                                    
                                    if  let start = times.first,
                                        let end = times.last,
                                        let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                        let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                        let string = "\(count)\n\(start) to \(end)\n" + text
                                        
                                        strings.append(string)
                                    }
                                }
                                break
                            }
                        }
                    }
                    
                    return strings
                }
                
                popover.editActionsAtIndexPath = popover.transcript?.rowActions
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTime:
            guard Globals.shared.mediaPlayer.currentTime != nil else {
                break
            }
            
            if let time = string.components(separatedBy: "\n")[1].components(separatedBy: " to ").first, let seconds = time.hmsToSeconds {
                Globals.shared.mediaPlayer.seek(to: seconds)
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
                    // Check if file exist
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error {
                            print("failed to remove old json file: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try fileManager.copyItem(at: location, to: destinationURL)
                        try fileManager.removeItem(at: location)
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

        if let mediaCategoryFilename = Globals.shared.mediaCategory.filename, let filename = task.taskDescription {
            print("filename: \(filename)")
            
            if let error = error {
                print("Download failed for: \(filename) with error: \(error.localizedDescription)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Couldn't get categories from network, try to get media, use last downloaded
                    if let mediaFileName = Globals.shared.mediaCategory.filename, let selectedID = Globals.shared.mediaCategory.selectedID {
                        downloadJSON(url:Constants.JSON.URL.MEDIA,filename:mediaFileName) // CATEGORY + selectedID
                    }
                    break
                    
                case mediaCategoryFilename:
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
                    if let mediaFileName = Globals.shared.mediaCategory.filename, let selectedID = Globals.shared.mediaCategory.selectedID {
                        downloadJSON(url:Constants.JSON.URL.MEDIA,filename:mediaFileName) // CATEGORY + selectedID
                    }
                    break
                    
                case mediaCategoryFilename:
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

class MediaTableViewController : UIViewController
{
    var display = Display()

    var popover : PopoverTableViewController?

    var actionsButton : UIBarButtonItem?
    
    var stringIndex : StringIndex? // [String:[String]]()

    @objc func finish()
    {
        Thread.onMainThread {
            self.popover?.activityIndicator?.stopAnimating()
            
            if self.stringIndex?.dict == nil {
                self.dismiss(animated: true, completion: nil)
                Alerts.shared.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase for transcription.")
            } else {
                self.actionsButton?.isEnabled = true
            }
        }
    }
    
    var changesPending = false
    
    var presentingVC : UIViewController?
    
    var jsonSource:JSONSource = .direct
    
    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
    }

    func deleteAllMedia()
    {
        let alert = UIAlertController(  title: "Confirm Deletion of All VoiceBase Media Items",
                                        message: nil,
                                        preferredStyle: .alert)
        alert.makeOpaque()
        
        let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
            (action : UIAlertAction!) -> Void in
            self.dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            VoiceBase.deleteAll()
        })
        alert.addAction(yesAction)
        
        let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        alert.addAction(noAction)
        
        present(alert, animated: true, completion: nil)
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

    var session:URLSession? // Used for JSON
    
    @IBOutlet weak var mediaCategoryButton: UIButton!
    @IBAction func mediaCategoryButtonAction(_ button: UIButton)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:mediaCategoryButtonAction", completion: nil)
            return
        }

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            setModalStyle(navigationController)

            navigationController.popoverPresentationController?.delegate = self
            
            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.sourceView = self.view
                navigationController.popoverPresentationController?.sourceRect = mediaCategoryButton.frame
            }

            popover.navigationItem.title = Constants.Strings.Select_Category
            
            popover.delegate = self
            popover.purpose = .selectingCategory
            
            popover.stringSelected = Globals.shared.mediaCategory.selected
            
            popover.section.strings = Globals.shared.mediaCategory.names
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
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
            refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControlEvents.valueChanged)

            if let refreshControl = refreshControl {
                tableView?.addSubview(refreshControl)
            }
            
            tableView?.allowsSelection = true

            //Eliminates blank cells at end.
            tableView?.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:show", completion: nil)
            return
        }

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            // In case one is already showing
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
      
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = button
            
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
            

            if let vClass = splitViewController?.traitCollection.verticalSizeClass,
                let isCollapsed = splitViewController?.isCollapsed,
                (vClass != UIUserInterfaceSizeClass.compact) || isCollapsed {
                if (Globals.shared.media.active?.scriptureIndex?.eligible != nil) {
                    showMenu.append(Constants.Strings.Scripture_Index)
                }
                
                if Globals.shared.media.active?.lexicon?.eligible != nil, Globals.shared.reachability.isReachable {
                    showMenu.append(Constants.Strings.Lexicon_Index)
                }
            } else {
                
            }
            
            showMenu.append(Constants.Strings.History)

            if Globals.shared.mediaStream.streamEntries != nil, Globals.shared.reachability.isReachable {
                showMenu.append(Constants.Strings.Live)
            }
            
            showMenu.append(Constants.Strings.Settings)
            
            showMenu.append(Constants.Strings.VoiceBase_API_Key)
            
            if Globals.shared.isVoiceBaseAvailable {
                showMenu.append(Constants.Strings.VoiceBase_Media)
            }
            
            popover.section.strings = showMenu

            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    var selectedMediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if selectedMediaItem != Globals.shared.selectedMediaItem.master {
                Globals.shared.selectedMediaItem.master = selectedMediaItem
            }
        }
    }
    
    func disableToolBarButtons()
    {
        Thread.onMainThread {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = false
                }
            }
        }
    }
    
    func disableBarButtons()
    {
        Thread.onMainThread {
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
        Thread.onMainThread {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMainThread {
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
    
    @objc func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:index", completion: nil)
            return
        }

        guard let grouping = Globals.shared.grouping else {
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
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
                    return bookNumberInBible(string) != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                }) {
                    popover.section.strings = books

                    if let other = Globals.shared.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                        return bookNumberInBible(string) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
                        popover.section.strings?.append(contentsOf: other)
                    }
                }
                break
                
            case GROUPING.TITLE:
                popover.section.showIndex = true
                popover.indexStringsTransform = stringWithoutPrefixes
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.CLASS:
                popover.section.showIndex = true
                popover.indexStringsTransform = stringWithoutPrefixes
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.SPEAKER:
                popover.section.showIndex = true
                popover.indexStringsTransform = lastNameFromName
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            default:
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                break
            }
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }

    @objc func grouping(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:grouping", completion: nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
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
            
            popover.purpose = .selectingGrouping
            popover.section.strings = Globals.shared.groupingTitles
            popover.stringSelected = translate(Globals.shared.grouping)
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    @objc func sorting(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:sorting", completion: nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
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
            
            popover.purpose = .selectingSorting
            popover.section.strings = Constants.SortingTitles
            popover.stringSelected = translate(Globals.shared.sorting)

            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
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
        let sortingButton = UIBarButtonItem(title: Constants.Strings.Menu.Sorting, style: UIBarButtonItemStyle.plain, target: self, action: #selector(sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Strings.Menu.Grouping, style: UIBarButtonItemStyle.plain, target: self, action: #selector(grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(index(_:)))

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
        
        if (Globals.shared.mediaRepository.list == nil) {
            disableBarButtons()
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func loadJSONDictsFromFileSystem(filename:String?,key:String) -> [[String:String]]? // CachesDirectory
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = filename?.fileSystemURL?.data?.json as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)"
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }

        return nil
    }
    
    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonFromURL(urlString: url,filename: filename) as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from URL, make sure that URL contains valid json.")
        }
        
        return nil
    }
    
    func mediaItemsFromMediaItemDicts(_ mediaItemDicts:[[String:String]]?) -> [MediaItem]?
    {
        return mediaItemDicts?.map({ (mediaItemDict:[String : String]) -> MediaItem in
            return MediaItem(storage: mediaItemDict)
        })
    }
    
    var liveEvents:[String:Any]?
    {
        get {
            return Constants.URL.LIVE_EVENTS.url?.data?.json as? [String:Any]
        }
    }
    
    func loadLive(completion:(()->(Void))?)
    {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            Globals.shared.mediaStream.streamEntries = self?.liveEvents?["streamEntries"] as? [[String:Any]]
            
            Thread.onMainThread {
                completion?()
            }
        }
    }
    
    func loadCategories()
    {
        if let categoriesDicts = self.loadJSONDictsFromURL(url: Constants.JSON.URL.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES,filename: Constants.JSON.FILENAME.CATEGORIES) {
            var mediaCategoryDicts = [String:String]()
            
            for categoriesDict in categoriesDicts {
                if let name = categoriesDict["category_name"] {
                    mediaCategoryDicts[name] = categoriesDict["id"]
                }
            }
            
            Globals.shared.mediaCategory.dicts = mediaCategoryDicts
        }
    }
    
    func loadTeachers()
    {
        if let teachersDicts = self.loadJSONDictsFromURL(url: Constants.JSON.URL.TEACHERS,key:Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES,filename: Constants.JSON.FILENAME.TEACHERS) {
            var mediaTeachersDict = [String:String]()
            
            for teachersDict in teachersDicts {
                if let name = teachersDict["name"] {
                    mediaTeachersDict[name] = teachersDict["status"]
                }
            }
            
            Globals.shared.mediaTeachers = mediaTeachersDict
        }
    }
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        Globals.shared.isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupSearchBar()
            self?.setupCategoryButton()
            self?.setupActionAndTagsButton()
            self?.setupBarButtons()
            self?.setupListActivityIndicator()

            Thread.onMainThread {
                self?.navigationItem.title = Constants.Title.Loading_Media
            }

            self?.loadLive(completion: nil)
            
            if let jsonSource = self?.jsonSource {
                switch jsonSource {
                case .download:
                    // From Caches Directory
                    if let categoriesDicts = self?.loadJSONDictsFromFileSystem(filename: Constants.JSON.FILENAME.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES) {
                        var mediaCategoryDicts = [String:String]()
                        
                        for categoriesDict in categoriesDicts {
                            if let name = categoriesDict["category_name"] {
                                mediaCategoryDicts[name] = categoriesDict["id"]
                            }
                        }
                        
                        Globals.shared.mediaCategory.dicts = mediaCategoryDicts
                    }
                    
                    if let teachersDicts = self?.loadJSONDictsFromFileSystem(filename: Constants.JSON.FILENAME.TEACHERS,key:Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES) {
                        var mediaTeachersDict = [String:String]()
                        
                        for teachersDict in teachersDicts {
                            if let name = teachersDict["category_name"] {
                                mediaTeachersDict[name] = teachersDict["status"]
                            }
                        }
                        
                        Globals.shared.mediaTeachers = mediaTeachersDict
                    }
                    
                    if  let mediaItemDicts = self?.loadJSONDictsFromFileSystem(filename:Globals.shared.mediaCategory.filename,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                        Globals.shared.mediaRepository.list = self?.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    } else {
                        Globals.shared.mediaRepository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                    
                case .direct:
                    self?.loadTeachers()
                    self?.loadCategories()

                    if  let url = Globals.shared.mediaCategory.url,
                        let filename = Globals.shared.mediaCategory.filename,
                        let mediaItemDicts = self?.loadJSONDictsFromURL(url: url,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES,filename: filename) {
                        Globals.shared.mediaRepository.list = self?.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    } else {
                        Globals.shared.mediaRepository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                }
            }

            Thread.onMainThread {
                self?.navigationItem.title = Constants.Title.Loading_Settings
            }
            Globals.shared.loadSettings()
            
            Thread.onMainThread {
                self?.navigationItem.title = Constants.Title.Sorting_and_Grouping
            }
            
            Globals.shared.media.all = MediaListGroupSort(mediaItems: Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                mediaItem.category == Globals.shared.mediaCategory.selected
            }))
            
            if Globals.shared.search.valid {
                Thread.onMainThread {
                    self?.searchBar.text = Globals.shared.search.text
                    self?.searchBar.showsCancelButton = true
                }

                Globals.shared.search.complete = false
            }

            self?.display.setup(Globals.shared.media.active)
            
            Thread.onMainThread {
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
    }
    
    func setupCategoryButton()
    {
        Thread.onMainThread {
            self.mediaCategoryButton.setTitle(Globals.shared.mediaCategory.selected)

            if Globals.shared.isLoading || Globals.shared.isRefreshing || !Globals.shared.search.complete {
                self.mediaCategoryButton.isEnabled = false
            } else {
                if Globals.shared.search.complete {
                    self.mediaCategoryButton.isEnabled = true
                }
            }
        }
    }
    
    func setupBarButtons()
    {
        if Globals.shared.isLoading || Globals.shared.isRefreshing {
            disableBarButtons()
        } else {
            if (Globals.shared.mediaRepository.list != nil) {
                enableBarButtons()
            }
        }
    }
    
    func setupListActivityIndicator()
    {
        if Globals.shared.isLoading || (Globals.shared.search.active && !Globals.shared.search.complete) {
            if !Globals.shared.isRefreshing {
                Thread.onMainThread {
                    self.startAnimating()
                }
            } else {
                Thread.onMainThread {
                    self.stopAnimating()
                }
            }
        } else {
            Thread.onMainThread {
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
        Thread.onMainThread {
            self.searchBar.resignFirstResponder()
            self.searchBar.placeholder = nil
            self.searchBar.text = nil
            self.searchBar.showsCancelButton = false
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:handleRefresh", completion: nil)
            return
        }
        
        Globals.shared.isRefreshing = true
        
        setupListActivityIndicator()
        refreshControl.beginRefreshing()
        
        Globals.shared.mediaPlayer.unobserve()
        
        Globals.shared.mediaPlayer.pause() // IfPlaying

        Globals.shared.mediaRepository.cancelAllDownloads()

        display.clear()
        
        Globals.shared.search.active = false

        setupSearchBar()
        
        tableView?.reloadData()
        
        // tableView can't be hidden or refresh spinner won't show.
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = false // Don't like it offset, just hide it for now
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)

        setupActionAndTagsButton()
        setupCategoryButton()

        setupBarButtons()
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        Globals.shared.media = Media()

        switch jsonSource {
        case .download:
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

    @objc func updateList()
    {
        updateSearch()
        
        display.setup(Globals.shared.media.active)

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

        Thread.onMainThread {
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
        
        Thread.onMainThread {
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

        if let view = loadingViewController.view {
            container = view
        }
        
        container.backgroundColor = UIColor.clear

        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView = loadingViewController.view.subviews[0]
        
        loadingView.isUserInteractionEnabled = false
        
        if let view = loadingView.subviews[0] as? UIActivityIndicatorView {
            actInd = view
        }
        
        actInd.isUserInteractionEnabled = false
        
        view.addSubview(container)
    }
    
    func loadCompletion()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if Globals.shared.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        }
        
        if Globals.shared.mediaRepository.list == nil {
            if Globals.shared.isRefreshing {
                self.refreshControl?.endRefreshing()
                Globals.shared.isRefreshing = false
            }

            alert(viewController:self,title: "No Media Available",message: "Please check your network connection and try again.",completion: nil)
        } else {
            if Globals.shared.isRefreshing {
                self.refreshControl?.endRefreshing()
                self.tableView?.setContentOffset(CGPoint(x:self.tableView.frame.origin.x, y:self.tableView.frame.origin.y - 44), animated: false)
                Globals.shared.isRefreshing = false
            }
            
            self.selectedMediaItem = Globals.shared.selectedMediaItem.master
            
            if Globals.shared.search.active && !Globals.shared.search.complete {
                self.updateSearchResults(Globals.shared.search.text,completion: {
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        Thread.onMainThread {
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    }
                })
            } else {
                // Reload the table
                self.tableView?.reloadData()

                if self.selectedMediaItem != nil {
                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                } else {
                    self.tableView?.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
                }
            }
        }
        
        self.setupTitle()
        self.tableView?.isHidden = false
        self.logo.isHidden = true
        
        if let goto = Globals.shared.media.goto {
            navigationController?.popToRootViewController(animated: false)
            Globals.shared.media.goto = nil 
            if let mediaItem = Globals.shared.mediaRepository.index?[goto] {
                Globals.shared.selectedMediaItem.master = mediaItem
                selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: .top)
               
                // Delay required for iPhone
                DispatchQueue.global(qos: .background).async {
                    Thread.onMainThread {
                        self.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    }
                }
//            } else {
//                if let category = Globals.shared.mediaCategory.selected {
//                    Alerts.shared.alert(title: "Unable to Find Media", message: "The media \(goto) is not in the current category: \(category)")
//                } else {
//                    Alerts.shared.alert(title: "Unable to Find Media", message: "The media \(goto) was not found.")
//                }
            }
        }
    }

    func load()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:load", completion: nil)
            return
        }
        
        guard !Globals.shared.isLoading else {
            return
        }
        
        guard Globals.shared.mediaRepository.list == nil else {
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
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finish), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.VOICE_BASE_FINISHED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playingPaused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING_PAUSED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lastSegue), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_LAST_SEGUE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        addNotifications()
        
        setupSortingAndGroupingOptions()
        setupShowMenu()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView?.estimatedRowHeight = tableView?.rowHeight
//        tableView?.rowHeight = UITableViewAutomaticDimension
    }
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        if Globals.shared.media.active?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:actions", completion: nil)
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
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
        
        if let mediaItemTags = Globals.shared.media.all?.mediaItemTags {
            strings.append(contentsOf: mediaItemTags)
        }
        
        return strings.sorted(by: {
            return $0.withoutPrefixes < $1.withoutPrefixes
        })
    }
    
    func setupActionAndTagsButton()
    {
        guard !Globals.shared.isLoading && !Globals.shared.isRefreshing else {
            Thread.onMainThread {
                self.navigationItem.rightBarButtonItems = nil
            }
            return
        }
        
        var barButtons = [UIBarButtonItem]()
        
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(actions))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        if actionMenu()?.count > 0, let actionButton = actionButton {
            barButtons.append(actionButton)
        }
        
        if (Globals.shared.media.all?.mediaItemTags?.count > 1) {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(selectingTagsAction(_:)))
        } else {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(selectingTagsAction(_:)))
        }
        tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags)

        if tagsMenu()?.count > 0, let tagsButton = tagsButton {
            barButtons.append(tagsButton)
        }
        
        Thread.onMainThread {
            if barButtons.count > 0 {
                self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
            } else {
                self.navigationItem.rightBarButtonItems = nil
            }
        }
    }
    
    func setModalStyle(_ navigationController:UINavigationController)
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            let hClass = traitCollection.horizontalSizeClass
            
            if hClass == .compact {
                navigationController.modalPresentationStyle = .overCurrentContext
            } else {
                // I don't think this ever happens: collapsed and regular
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            }
        } else {
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
        }
    }
    
    @IBAction func selectingTagsAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:selectingTagsAction", completion: nil)
            return
        }

        guard !Globals.shared.isLoading else {
            return
        }
        
        guard !Globals.shared.isRefreshing else {
            return
        }
        
        guard (Globals.shared.media.all?.mediaItemTags != nil) else {
            return
        }
        
        guard (storyboard != nil) else {
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            setModalStyle(navigationController)

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
            popover.indexStringsTransform = stringWithoutPrefixes

            popover.section.strings = tagsMenu()
            
            popover.search = popover.section.strings?.count > 10
            
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
        
        if !Globals.shared.search.active || (Globals.shared.search.text?.uppercased() == searchText) {
            display.setup(Globals.shared.media.active)
        }
        
        Thread.onMainThread {
            if !self.tableView.isEditing {
                self.tableView.reloadData()
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
        
        if Globals.shared.media.toSearch?.searches == nil {
            Globals.shared.media.toSearch?.searches = ThreadSafeDictionary<MediaListGroupSort>(name: UUID().uuidString + "SEARCH") // [String:MediaListGroupSort]()
        }
        
        Globals.shared.media.toSearch?.searches?[searchText] = MediaListGroupSort(mediaItems: mediaItems)
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard !searchText.isEmpty else {
            return
        }
        
        guard (Globals.shared.media.toSearch?.searches?[searchText] == nil) else {
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
            return !Globals.shared.search.valid || (Globals.shared.search.text != searchText)
        }
        
        Globals.shared.search.complete = false

        display.clear()

        Thread.onMainThread {
            self.tableView?.reloadData()
        }

        self.setupActionAndTagsButton()
        self.setupBarButtons()
        self.setupCategoryButton()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var searchMediaItems:[MediaItem]?
            
            if let mediaItems = Globals.shared.media.toSearch?.list {
                for mediaItem in mediaItems {
                    Globals.shared.search.complete = false
                    
                    self?.setupListActivityIndicator()
                    
                    let searchHit = mediaItem.search(searchText)
                    
                    abort = abort || shouldAbort()
                    
                    if abort {
                        Globals.shared.media.toSearch?.searches?[searchText] = nil
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
                                    self?.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                                    self?.updateDisplay(searchText:searchText)
                                }
                            }
                        }
                    }
                }
                
                if !abort {
                    self?.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                    self?.updateDisplay(searchText:searchText)
                } else {
                    Globals.shared.media.toSearch?.searches?[searchText] = nil
                }
                
                if !abort && Globals.shared.search.transcripts, let mediaItems = Globals.shared.media.toSearch?.list {
                    for mediaItem in mediaItems {
                        Globals.shared.search.complete = false
                        
                        self?.setupListActivityIndicator()

                        var searchHit = false
                        
                        autoreleasepool {
                            searchHit = mediaItem.searchNotes(searchText)
                        }

                        abort = abort || shouldAbort() || !Globals.shared.search.transcripts
                        
                        if abort {
                            Globals.shared.media.toSearch?.searches?[searchText] = nil
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
                                    
                                    self?.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                                    self?.updateDisplay(searchText:searchText)
                                }
                            }
                        }
                    }
                }
            }
            
            // Final search update since we're only doing them in batches of Constants.SEARCH_RESULTS_BETWEEN_UPDATES
            
            abort = abort || shouldAbort()
            
            if abort {
                Globals.shared.media.toSearch?.searches?[searchText] = nil
            } else {
                self?.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                self?.updateDisplay(searchText:searchText)
            }
            
            Thread.onMainThread {
                completion?()
                
                Globals.shared.search.complete = true
                
                self?.setupListActivityIndicator()
                self?.setupBarButtons()
                self?.setupCategoryButton()
                self?.setupActionAndTagsButton()
            }
        }
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
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
        
        guard let mediaItems = Globals.shared.media.active?.mediaItems else {
            return
        }
        
        guard let index = mediaItems.index(of: mediaItem) else {
            print("No index")
            return
        }

        print("index")

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
        
        if let sectionIndex = sectionIndex, let stringIndex = indexStrings.index(of: sectionIndex) {
            section = stringIndex
        }
        
        if let sectionIndexes = Globals.shared.media.active?.sectionIndexes {
            row = index - sectionIndexes[section]
        }
        
        if (section >= 0) && (row >= 0) {
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

            Thread.onMainThread {
                self.tableView?.setEditing(false, animated: true)
                
                if (select) {
                    self.tableView?.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                }
                
                if (scroll) {
                    //Scrolling when the user isn't expecting it can be jarring.
                    self.tableView?.scrollToRow(at: indexPath, at: position, animated: false)
                }
            }
        }
    }
    
    func setupTag()
    {
        guard let showing = Globals.shared.media.tags.showing else {
            return
        }
        
        Thread.onMainThread {
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
                if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
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
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
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
        guard Globals.shared.search.valid else {
            return
        }
        
        updateSearchResults(Globals.shared.search.text,completion: nil)
    }
    
    @objc func liveView()
    {
        self.dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: nil)
    }
    
    @objc func playingPaused()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: Globals.shared.mediaPlayer.mediaItem ?? Globals.shared.selectedMediaItem.detail)
    }
    
    @objc func lastSegue()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: Globals.shared.selectedMediaItem.detail)
    }
    
    @objc func deviceOrientationDidChange()
    {

    }

    @objc func stopEditing()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:stopEditing", completion: nil)
            return
        }
        
        tableView.isEditing = false
    }
    
    @objc func willEnterForeground()
    {
        
    }
    
    @objc func didBecomeActive()
    {
        guard !Globals.shared.isLoading, Globals.shared.mediaRepository.list == nil else {
            return
        }
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:didBecomeActive", completion: nil)
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

        updateUI()
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = false
        }

        setupCategoryButton()
        
        setupTag()
        setupActionAndTagsButton()
        
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

        if self.presentingVC?.popoverPresentationController?.presentationStyle == .popover {
            self.dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
        }

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setupTitle()
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
        
        cell.searchText = Globals.shared.search.active ? Globals.shared.search.text : nil
        
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

            if let superview = label.superview {
                let centerY = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
                label.superview?.addConstraint(centerY)

                let leftMargin = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.leftMargin, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.leftMargin, multiplier: 1.0, constant: 0.0)
                label.superview?.addConstraint(leftMargin)
            }
            
//            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
//            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllLeft], metrics: nil, views: ["label":label]))
            
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
        Thread.onMainThread {
            self.searchBar.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMainThread {
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
                let alert = UIAlertController(  title: Constants.Strings.Actions,
                                                message: message,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                if let alertActions = cell.mediaItem?.editActions(viewController: self) {
                    for alertAction in alertActions {
                        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                            alertAction.handler?()
                        })
                        alert.addAction(action)
                    }
                }
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction) -> Void in
                })
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            action.backgroundColor = UIColor.controlBlue()
            
            return [action]
        }
        
        return nil
    }
}
