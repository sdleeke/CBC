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
        
        globals.search.text = searchText
        
        if (searchText != Constants.EMPTY_STRING) { //
            updateSearchResults(searchText,completion: nil)
        } else {
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

        searchBar.resignFirstResponder()

        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid {
            updateSearchResults(searchBar.text,completion: nil)
        } else {
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
        
        return !globals.isLoading && !globals.isRefreshing && (globals.media.all != nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        globals.search.active = true
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidBeginEditing", completion: nil)
            return
        }
        
        searchBar.showsCancelButton = true
        
        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid { //
            updateSearchResults(searchText,completion: nil)
        } else {
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
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        globals.search.active = false
        
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
        
        globals.search.text = nil
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        disableBarButtons()
        
        globals.clearDisplay()
        
        tableView?.reloadData()
        
        startAnimating()
        
        globals.setupDisplay(globals.media.active)
        
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

extension MediaTableViewController : PopoverPickerControllerDelegate
{
    // MARK: PopoverPickerControllerDelegate
    
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
                self.logo.isHidden = true // Don't like it offset, just hide it for now
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
            self.loadCompletion()
        }
    }
}

class StringIndex : NSObject
{
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
    
    func stringIndex(key:String,sort:((String,String)->(Bool))?) -> [String:[String]]?
    {
        guard let keys = dict?.keys.sorted() else {
            return nil
        }
        
        var stringIndex = [String:[String]]()
        
        for dk in keys {
            if let values = dict?[dk] {
                for value in values {
                    if let string = value[key] as? String {
                        if stringIndex[dk] == nil {
                            stringIndex[dk] = [string]
                        } else {
                            stringIndex[dk]?.append(string)
                        }
                    }
                }
            }
        }
        
        if let sort = sort {
            for key in stringIndex.keys {
                stringIndex[key] = stringIndex[key]?.sorted(by: { (lhs:String, rhs:String) -> Bool in
                    return sort(lhs,rhs)
                })
            }
        }
        
        return stringIndex.count > 0 ? stringIndex : nil
    }
    
    convenience init?(mediaItems:[[String:Any]]?,sort:(([String:Any],[String:Any])->(Bool))?)
    {
        self.init()
        
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        var dict = [String:[[String:Any]]]()

        for mediaItem in mediaItems {
            if  let mediaID = mediaItem["mediaId"] as? String,
                let metadata = mediaItem["metadata"] as? [String:Any],
                let title = metadata["title"] as? String,
                let device = metadata["device"] as? [String:String],
                var deviceName = device["name"] {
                if deviceName == UIDevice.current.deviceName {
                    deviceName += " (this device)"
                }
                
                if dict[deviceName] == nil {
                    dict[deviceName] = [["title":title,"mediaID":mediaID,"metadata":metadata as Any]]
                } else {
                    dict[deviceName]?.append(["title":title,"mediaID":mediaID,"metadata":metadata as Any])
                }
            } else {
                print("Unable to add: \(mediaItem)")
            }
        }
        
        if let sort = sort {
            let keys = dict.keys.map({ (string:String) -> String in
                return string
            })
            
            for key in keys {
                dict[key] = dict[key]?.sorted(by: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                    return sort(lhs,rhs)
                })
            }
        }
        
        if dict.count > 0 {
            self.dict = dict
        } else {
            return nil
        }
    }
}

extension MediaTableViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        guard self.actionsButton?.isEnabled == true else {
            return nil
        }
        
        var actions = [AlertAction]()
        
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
        
        if let mediaID = value["mediaID"] as? String,let title = value["title"] as? String {
            actions.append(AlertAction(title: Constants.Strings.Delete, style: .destructive) {
                let alert = UIAlertController(  title: "Confirm Deletion of VoiceBase Media Item",
                                                message: title + "\n created on \(key == UIDevice.current.deviceName ? "this device" : key)",
                    preferredStyle: .alert)
                
                alert.makeOpaque()
                
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
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
                                    if (value["mediaID"] as? String) == mediaID {
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
                    
                    Thread.onMainThread() {
                        popover.tableView?.isEditing = false
                        popover.tableView?.reloadData()
                        popover.tableView?.reloadData()
                    }
                })
                alert.addAction(yesAction)
                
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(noAction)
                
                let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            })
            
            actions.append(AlertAction(title: "ID", style: .default) {
                let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                message: nil,
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
            
            if let popover = self.popover {
                actions.append(AlertAction(title: "Information", style: .default) {
                    process(viewController: popover, work: { () -> (Any?) in
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
                        
                        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                            let popover = navigationController.viewControllers[0] as? WebViewController {
                            
                            popover.html.fontSize = 12
                            popover.html.string = insertHead(VoiceBase.html(json),fontSize: popover.html.fontSize)
                            
                            popover.search = true
                            popover.content = .html
                            
                            popover.navigationItem.title = "VoiceBase Media Item"
                            
                            self.popover?.navigationController?.pushViewController(popover, animated: true)
                        }
                    })
                })

                actions.append(AlertAction(title: "Inspector", style: .default) {
                    process(viewController: popover, work: { () -> (Any?) in
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
                        
                        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                            popover.search = true
                            
                            popover.navigationItem.title = "VoiceBase Media Item"
                            
                            popover.stringsAny = json
                            popover.purpose = .showingVoiceBaseMediaItem
                            
                            self.popover?.navigationController?.pushViewController(popover, animated: true)
                        }
                    })
                })
            }
        }

        if let mediaID = value["mediaID"] as? String {
            if let mediaList = globals.media.all?.list {
                if let mediaItem = mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                        return transcript.mediaID == mediaID
                    }).count == 1
                }).first {
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
                            //                                                            self.popover?.section.indexHeaders = self.popover?.section.headers
                            
                            self.popover?.section.counts = counts.count > 0 ? counts : nil
                            self.popover?.section.indexes = indexes.count > 0 ? indexes : nil
                            
                            self.popover?.tableView?.isEditing = false
                            
                            self.popover?.tableView?.reloadData()
                            self.popover?.tableView?.reloadData()
                        })
                        alert.addAction(yesAction)
                        
                        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction) -> Void in
                            
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
                            (action : UIAlertAction) -> Void in
                        })
                        alert.addAction(okayAction)
                        
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    if let popover = self.popover {
                        actions.append(AlertAction(title: "Details", style: .default, action: {
                            process(viewController: popover, work: { () -> (Any?) in
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
                                
                                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
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
                            process(viewController: popover, work: { () -> (Any?) in
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
                                
                                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                                    popover.search = true
                                    
                                    popover.navigationItem.title = "VoiceBase Media Item"
                                    
                                    popover.stringsAny = json
                                    popover.purpose = .showingVoiceBaseMediaItem
                                    
                                    self.popover?.navigationController?.pushViewController(popover, animated: true)
                                }
                            })
                        }))
                    }
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: nil))
                    
                    globals.alert(title:"VoiceBase Media Item\nNot in Use", message:"While created on this device:\n\n\(title)\n\nno longer appears to be in use.", actions:actions)
                }
            }
        }
    }
    
    func historyActions()
    {
        let alert = UIAlertController(title: "Delete History?",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.makeOpaque()
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive, handler: { (alert:UIAlertAction!) -> Void in
            globals.history = nil
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: Constants.SETTINGS.HISTORY)
            defaults.synchronize()
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(yesAction)

        let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (alert:UIAlertAction!) -> Void in

        })
        alert.addAction(cancelAction)
        
        Thread.onMainThread() {
            self.present(alert, animated: true, completion: nil)
        }
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
                if let contains = globals.media.active?.mediaItems?.contains(mediaItem), contains {
                    if tableView.isEditing {
                        tableView.setEditing(false, animated: true)
                        DispatchQueue.global(qos: .background).async {
                            Thread.sleep(forTimeInterval: 0.1)
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    } else {
                        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                    }
                } else {
                    if let text = mediaItem.text, let contextTitle = globals.contextTitle {
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
            globals.mediaPlayer.killPIP = true

            performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: globals.mediaPlayer.mediaItem)
            break
            
        case Constants.Strings.Scripture_Index:
            if (globals.media.active?.scriptureIndex?.eligible == nil) {
                alert(viewController:self,title:"No Scripture Index Available",message: "The Scripture references for these media items are not specific.",completion:nil)
            } else {
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SCRIPTURE_INDEX) as? ScriptureIndexViewController {
                    
                    viewController.mediaListGroupSort = globals.media.active
                    
                    navigationController?.pushViewController(viewController, animated: true)
                }
            }
            break
            
        case Constants.Strings.Lexicon_Index:
            if (globals.media.active?.lexicon?.eligible == nil) {
                alert(viewController:self,title:"No Lexicon Index Available",
                      message: "These media items do not have HTML transcripts.",
                      completion:nil)
            } else {
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.LEXICON_INDEX) as? LexiconIndexViewController {
                    viewController.mediaListGroupSort = globals.media.active
                    
                    navigationController?.pushViewController(viewController, animated: true)
                }
            }
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
                    let strings = globals.relevantHistoryList
                    
                    if strings == nil {
                        Thread.onMainThread(block: { () -> (Void) in
                            popover.navigationItem.leftBarButtonItem?.isEnabled = false
                            popover.activityIndicator.stopAnimating()
                            alert(viewController:self,title: "History is empty.",
                                  message: nil,
                                  completion:{
                                    self.presentingVC = nil
                                    self.dismiss(animated: true, completion: nil)
                            })
                        })
                    }
                    
                    return strings
                }
                
                popover.vc = self.splitViewController
                
                popover.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Delete All", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.historyActions))
                
                present(navigationController, animated: true, completion: {
                    self.presentingVC = navigationController
                })
            }
            break
            
        case Constants.Strings.Live:
            if  globals.streamEntries?.count > 0, globals.reachability.isReachable,
                let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
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
                })
            }
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
                textField.text = globals.voiceBaseAPIKey
            })
            
            let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction) -> Void in
                globals.voiceBaseAPIKey = alert.textFields?[0].text
            })
            alert.addAction(okayAction)

            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                (action : UIAlertAction) -> Void in
            })
            alert.addAction(cancel)
            
            present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.VoiceBase_Media:
            guard globals.reachability.isReachable else {
                return
            }
            
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self

                self.popover = navigationController.viewControllers[0] as? PopoverTableViewController
                
                self.actionsButton = UIBarButtonItem(title: "Actions", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.voiceBaseActions))
                
                self.popover?.navigationItem.leftBarButtonItem = self.actionsButton
                
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
                        
                        self.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                            if  var date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                                var date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                                if let range = date0.range(of: " PM") {
                                    date0 = date0.substring(to: range.lowerBound)
                                }
                                if let range = date0.range(of: " AM") {
                                    date0 = date0.substring(to: range.lowerBound)
                                }

                                if let range = date1.range(of: " PM") {
                                    date1 = date1.substring(to: range.lowerBound)
                                }
                                if let range = date1.range(of: " AM") {
                                    date1 = date1.substring(to: range.lowerBound)
                                }

                                return Date(string: date0) < Date(string: date1)
                            } else {
                                return false // arbitrary
                            }
                        })
                        
                        self.popover?.section.stringIndex = self.stringIndex?.stringIndex(key: "title", sort: nil)

                        Thread.onMainThread(block: {
                            self.popover?.updateSearchResults()
                            
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
                        })
                    },onError: nil)
                }
                
                self.popover?.editActionsAtIndexPath = self.rowActions
                
                self.popover?.delegate = self
                self.popover?.purpose = .showingVoiceBaseMediaItems
                self.popover?.allowsSelection = false
                
                self.popover?.section.showHeaders = true
                
                self.popover?.search = true
                
                self.popover?.vc = self.splitViewController
                
                self.present(navigationController, animated: true, completion: {
                    self.popover?.activityIndicator.startAnimating()
                    
                    VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        // Begin by separating media into what was created on this device and what was created on something else.
                        self.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                            if  var date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                                var date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                                if let range = date0.range(of: " PM") {
                                    date0 = date0.substring(to: range.lowerBound)
                                }
                                if let range = date0.range(of: " AM") {
                                    date0 = date0.substring(to: range.lowerBound)
                                }

                                if let range = date1.range(of: " PM") {
                                    date1 = date1.substring(to: range.lowerBound)
                                }
                                if let range = date1.range(of: " AM") {
                                    date1 = date1.substring(to: range.lowerBound)
                                }

                                return Date(string: date0) < Date(string: date1)
                            } else {
                                return false // arbitrary
                            }
                        })
                        
                        self.popover?.section.stringIndex = self.stringIndex?.stringIndex(key: "title", sort: nil)
                        
                        self.popover?.updateSearchResults()
                        
                        Thread.onMainThread(block: { (Void) -> (Void) in
                            self.popover?.tableView?.reloadData()
                            self.popover?.activityIndicator.stopAnimating()
                        })
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
                    self.logo.isHidden = true // Don't like it offset, just hide it for now
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
                Thread.onMainThread(block: {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
                })
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
                
                if let mediaItem = globals.mediaRepository.index?[mediaItemID] {
                    if mediaItem.text != strings[index] {
                        if let text = mediaItem.text {
                            print(text,strings[index])
                        }
                    }
                    
                    if let contains = globals.media.active?.mediaItems?.contains(mediaItem), contains {
                        selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                    } else {
                        //                        dismiss(animated: true, completion: nil)
                        
                        if let text = mediaItem.text, let contextTitle = globals.contextTitle {
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
            // Should we be showing globals.media.active?.mediaItemTags instead?  That would be the equivalent of drilling down.
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch string {
                    case Constants.Strings.All:
                        if (globals.media.tags.showing != Constants.ALL) {
                            new = true
                            globals.media.tags.selected = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        
                        let tagSelected = strings[index]
                        
                        new = (globals.media.tags.showing != Constants.TAGGED) || (globals.media.tags.selected != tagSelected)
                        
                        if (new) {
                            globals.media.tags.selected = tagSelected
                        }
                        break
                    }
                    
                    if (new) {
                        Thread.onMainThread() {
                            globals.clearDisplay()
                            
                            self.tableView?.reloadData()
                            
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
                    presentHTMLModal(viewController: self, mediaItem: nil, style: .overFullScreen, title: globals.contextTitle, htmlString: string)
                } else {
                    process(viewController: self, work: { () -> (Any?) in
                        if globals.media.active?.html?.string == nil {
                            globals.media.active?.html?.string = setupMediaItemsHTMLGlobal(includeURLs: true, includeColumns: true)
                        }
                        return globals.media.active?.html?.string
                    }, completion: { (data:Any?) in
                        presentHTMLModal(viewController: self, mediaItem: nil, style: .overFullScreen, title: globals.contextTitle, htmlString: data as? String)
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
        
        if let filename = downloadTask.taskDescription {
            print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        print("countOfBytesReceived: \(downloadTask.countOfBytesReceived)")
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        if let filename = downloadTask.taskDescription {
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
                    } catch let error as NSError {
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

        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
        //        removeTempFiles()
        
        if let mediaCategoryFilename = globals.mediaCategory.filename, let filename = task.taskDescription {
            print("filename: \(filename)")
            
            if let error = error {
                print("Download failed for: \(filename) with error: \(error.localizedDescription)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Couldn't get categories from network, try to get media, use last downloaded
                    if let mediaFileName = globals.mediaCategory.filename, let selectedID = globals.mediaCategory.selectedID {
                        downloadJSON(url:Constants.JSON.URL.CATEGORY + selectedID,filename:mediaFileName)
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
                    if let mediaFileName = globals.mediaCategory.filename, let selectedID = globals.mediaCategory.selectedID {
                        downloadJSON(url:Constants.JSON.URL.CATEGORY + selectedID,filename:mediaFileName)
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

class MediaTableViewController : UIViewController // MediaController
{
    var popover : PopoverTableViewController?
    var actionsButton : UIBarButtonItem?
    
    var stringIndex : StringIndex? // [String:[String]]()

    func finish()
    {
        Thread.onMainThread() {
            self.popover?.activityIndicator?.stopAnimating()
            
            if self.stringIndex?.dict == nil {
                self.dismiss(animated: true, completion: nil)
                globals.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase for transcription.")
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
            (action : UIAlertAction!) -> Void in
            self.dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            VoiceBase.deleteAll()
        })
        alert.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        alert.addAction(noAction)
        
        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func voiceBaseActions()
    {
        let alert = UIAlertController(  title: "VoiceBase Actions",
                                        message: nil,
                                        preferredStyle: .alert)
        alert.makeOpaque()
        
        let deleteAllAction = UIAlertAction(title: "Delete All", style: UIAlertActionStyle.destructive, handler: {
            (action : UIAlertAction!) -> Void in
            self.deleteAllMedia()
        })
        alert.addAction(deleteAllAction)
        
        let loadAllAction = UIAlertAction(title: "Load All", style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            VoiceBase.load()
        })
        alert.addAction(loadAllAction)
        
        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func downloadFailed(_ notification:NSNotification)
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

            navigationController.popoverPresentationController?.delegate = self
            
            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.sourceView = self.view
                navigationController.popoverPresentationController?.sourceRect = mediaCategoryButton.frame
            }

            popover.navigationItem.title = Constants.Strings.Select_Category
            
            popover.delegate = self
            popover.purpose = .selectingCategory
            
            popover.stringSelected = globals.mediaCategory.selected
            
            popover.section.strings = globals.mediaCategory.names
            
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
        didSet {
            tableView.register(MediaTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "MediaTableViewController")

            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)

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
            if (globals.display.mediaItems != nil) && (selectedMediaItem != nil) {
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
                
                if let count = splitViewController?.viewControllers.count, count > 1 {
                    if let nvc = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
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
            
            showMenu.append(Constants.Strings.History)

            if globals.streamEntries != nil, globals.reachability.isReachable {
                showMenu.append(Constants.Strings.Live)
            }
            
            showMenu.append(Constants.Strings.Settings)
            
            showMenu.append(Constants.Strings.VoiceBase_API_Key)
            
            if globals.isVoiceBaseAvailable ?? false {
                showMenu.append(Constants.Strings.VoiceBase_Media)
            }
            
            popover.section.strings = showMenu

            popover.vc = self.splitViewController

            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            if selectedMediaItem != globals.selectedMediaItem.master {
                globals.selectedMediaItem.master = selectedMediaItem
            }
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
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:index", completion: nil)
            return
        }

        guard let grouping = globals.grouping else {
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
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
                if let books = globals.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                    return bookNumberInBible(string) != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                }) {
                    popover.section.strings = books

                    if let other = globals.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                        return bookNumberInBible(string) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
                        popover.section.strings?.append(contentsOf: other)
                    }
                }
                break
                
            case GROUPING.TITLE:
                popover.section.showIndex = true
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.CLASS:
                popover.section.showIndex = true
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.SPEAKER:
                popover.section.showIndex = true
                popover.indexStringsTransform = lastNameFromName
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            default:
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
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:grouping", completion: nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
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
            popover.section.strings = globals.groupingTitles
            popover.stringSelected = translate(globals.grouping)

            popover.vc = self.splitViewController
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    func sorting(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:sorting", completion: nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
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
            popover.stringSelected = translate(globals.sorting)
            
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
        showButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.disabled)
        showButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.selected)

        showButton?.isEnabled = (globals.media.all != nil)
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
        
        if let json = jsonFromURL(url: url,filename: filename) as? [String:Any] {
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
            return MediaItem(dict: mediaItemDict)
        })
    }
    
    func loadLive() -> [String:Any]?
    {
        return jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any]
    }
    
    func loadLive(completion:(()->(Void))?)
    {
        DispatchQueue.global(qos: .background).async() {
            Thread.sleep(forTimeInterval: 0.25)
        
            if let liveEvents = jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any] {
                globals.streamEntries = liveEvents["streamEntries"] as? [[String:Any]]
                
                Thread.onMainThread(block: {
                    completion?()
                })
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
            
            globals.mediaCategory.dicts = mediaCategoryDicts
        }
    }
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        globals.isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
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
                    var mediaCategoryDicts = [String:String]()
                    
                    for categoriesDict in categoriesDicts {
                        if let name = categoriesDict["category_name"] {
                            mediaCategoryDicts[name] = categoriesDict["id"]
                        }
                    }
                    
                    globals.mediaCategory.dicts = mediaCategoryDicts
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
                self.loadCategories()
                
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
            
            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Loading_Settings
            }
            globals.loadSettings()
            
            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Sorting_and_Grouping
            }
            
            globals.media.all = MediaListGroupSort(mediaItems: globals.mediaRepository.list)
            
            if globals.search.valid {
                Thread.onMainThread() {
                    self.searchBar.text = globals.search.text
                    self.searchBar.showsCancelButton = true
                }

                globals.search.complete = false
            }

            globals.setupDisplay(globals.media.active)
            
            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (globals.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    globals.mediaPlayer.setup(globals.mediaPlayer.mediaItem,playOnLoad:false)
                }

                self.navigationItem.title = Constants.CBC.TITLE.SHORT
                
                if (self.splitViewController?.viewControllers.count > 1) {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
                }
                
                globals.isLoading = false
                
                completion?()

                self.updateUI()
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
                if globals.search.complete {
                    self.mediaCategoryButton.isEnabled = true
                }
            }
        }
    }
    
    func setupBarButtons()
    {
        if globals.isLoading || globals.isRefreshing {
            disableBarButtons()
        } else {
            if (globals.mediaRepository.list != nil) {
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
        
        if globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        }
        
        if globals.mediaRepository.list == nil {
            if globals.isRefreshing {
                self.refreshControl?.endRefreshing()
                globals.isRefreshing = false
            }

            alert(viewController:self,title: "No Media Available",message: "Please check your network connection and try again.",completion: nil)
        } else {
            if globals.isRefreshing {
                self.refreshControl?.endRefreshing()
                self.tableView?.setContentOffset(CGPoint(x:self.tableView.frame.origin.x, y:self.tableView.frame.origin.y - 44), animated: false)
                globals.isRefreshing = false
            }
            
            self.selectedMediaItem = globals.selectedMediaItem.master
            
            if globals.search.active && !globals.search.complete {
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
    }

    func load()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:load", completion: nil)
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
            logo.isHidden = true
        }
        
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
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.finish), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.VOICE_BASE_FINISHED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.playingPaused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING_PAUSED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.lastSegue), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_LAST_SEGUE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
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
        
        navigationController?.isToolbarHidden = false
    }
    
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
        
        return strings.sorted(by: {
            if let first = stringWithoutPrefixes($0), let second = stringWithoutPrefixes($1) {
                return first < second
            }
            
            return stringWithoutPrefixes($0) != nil
        })
    }
    
    func setupActionAndTagsButton()
    {
        guard !globals.isLoading && !globals.isRefreshing else {
            Thread.onMainThread(block: {
                self.navigationItem.rightBarButtonItems = nil
            })
            return
        }
        
        var barButtons = [UIBarButtonItem]()
        
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.actions))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.disabled)

        if actionMenu()?.count > 0, let actionButton = actionButton {
            barButtons.append(actionButton)
        }
        
        if (globals.media.all?.mediaItemTags?.count > 1) {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.selectingTagsAction(_:)))
        } else {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.selectingTagsAction(_:)))
        }
        tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.normal)
        tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.disabled)

        if tagsMenu()?.count > 0, let tagsButton = tagsButton {
            barButtons.append(tagsButton)
        }
        
        Thread.onMainThread(block: {
            if barButtons.count > 0 {
                self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
            } else {
                self.navigationItem.rightBarButtonItems = nil
            }
        })
    }
    
    @IBAction func selectingTagsAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:selectingTagsAction", completion: nil)
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

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            
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

            navigationController.popoverPresentationController?.delegate = self

            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = tagsButton
            }

            popover.navigationItem.title = Constants.Strings.Show
            
            popover.delegate = self
            popover.purpose = .selectingTags
            
            popover.stringSelected = globals.media.tags.selected ?? Constants.Strings.All
            
            popover.section.showIndex = true
            
            popover.section.strings = tagsMenu()
            
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
            globals.setupDisplay(globals.media.active)
        }
        
        Thread.onMainThread() {
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
        
        if globals.media.toSearch?.searches == nil {
            globals.media.toSearch?.searches = [String:MediaListGroupSort]()
        }
        
        globals.media.toSearch?.searches?[searchText] = MediaListGroupSort(mediaItems: mediaItems)
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard !searchText.isEmpty else {
            return
        }
        
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

        globals.clearDisplay()

        Thread.onMainThread() {
            self.tableView?.reloadData()
        }

        self.setupActionAndTagsButton()
        self.setupBarButtons()
        self.setupCategoryButton()

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            var searchMediaItems:[MediaItem]?
            
            if let mediaItems = globals.media.toSearch?.list {
                for mediaItem in mediaItems {
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
                            
                            if let count = searchMediaItems?.count, ((count % Constants.SEARCH_RESULTS_BETWEEN_UPDATES) == 0) {
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
                
                if !abort && globals.search.transcripts, let mediaItems = globals.media.toSearch?.list {
                    for mediaItem in mediaItems {
                        globals.search.complete = false
                        
                        self.setupListActivityIndicator()

                        let searchHit = mediaItem.searchFullNotesHTML(searchText)

                        abort = abort || shouldAbort() || !globals.search.transcripts
                        
                        if abort {
                            globals.media.toSearch?.searches?[searchText] = nil
                            break
                        } else {
                            if searchHit {
                                if searchMediaItems == nil {
                                    searchMediaItems = [mediaItem]
                                } else
                                
                                if let contains = searchMediaItems?.contains(mediaItem), !contains {
                                    searchMediaItems?.append(mediaItem)
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
        guard !tableView.isEditing else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let grouping = globals.grouping else {
            return
        }
        
        guard let indexStrings = globals.media.active?.section?.indexStrings else {
            return
        }
        
        guard let mediaItems = globals.media.active?.mediaItems else {
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
        
        if let sectionIndexes = globals.media.active?.sectionIndexes {
            row = index - sectionIndexes[section]
        }
        
        //            print(section)
        
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

            Thread.onMainThread() {
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

    
    fileprivate func setupTag()
    {
        guard let showing = globals.media.tags.showing else {
            return
        }
        
        Thread.onMainThread() {
            switch showing {
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
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: globals.mediaPlayer.mediaItem ?? globals.selectedMediaItem.detail)
    }
    
    func lastSegue()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: globals.selectedMediaItem.detail)
    }
    
    func deviceOrientationDidChange()
    {

    }

    func stopEditing()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:stopEditing", completion: nil)
            return
        }
        
        tableView.isEditing = false
    }
    
    func willEnterForeground()
    {
        
    }
    
    func didBecomeActive()
    {
        guard !globals.isLoading, globals.mediaRepository.list == nil else {
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

        // Happens in didBecomeActive.
//        load()

        addNotifications()

        updateUI()
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
        
        setupTitle()
        
        setupBarButtons()

        setupListActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        navigationController?.isToolbarHidden = false
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
                globals.mediaPlayer.killPIP = true
                
                if sender != nil {
                    (dvc as? LiveViewController)?.streamEntry = sender as? StreamEntry
                } else {
                    let defaults = UserDefaults.standard
                    if let streamEntry = StreamEntry(defaults.object(forKey: Constants.SETTINGS.LIVE) as? [String:Any]) {
                        (dvc as? LiveViewController)?.streamEntry = streamEntry
                    }
                }
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
                
                if let myCell = sender as? MediaTableViewCell {
                    if (selectedMediaItem != myCell.mediaItem) || (globals.history == nil) {
                        globals.addToHistory(myCell.mediaItem)
                    }
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
            self.setupTitle()
        }
    }
}

extension MediaTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int
    {
        guard let headers = globals.display.section.headers else {
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
        guard let headers = globals.display.section.headers else {
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
        guard let counts = globals.display.section.counts else {
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
        
        cell.searchText = globals.search.active ? globals.search.text : nil
        
        // Configure the cell
        if indexPath.section >= 0, indexPath.section < globals.display.section.indexes?.count {
            if let section = globals.display.section.indexes?[indexPath.section], let count = globals.display.mediaItems?.count {
                if (section + indexPath.row) >= 0,(section + indexPath.row) < count {
                    cell.mediaItem = globals.display.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
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
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":label]))
            
            view?.label = label
        }
        
        view?.alpha = 0.85
        
        if section >= 0, section < globals.display.section.headers?.count, let title = globals.display.section.headers?[section] {
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
        if globals.mediaPlayer.fullScreen {
            globals.mediaPlayer.fullScreen = false
        }

        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
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
    
    func tableView(_ tableView:UITableView, didDeselectRowAt indexPath: IndexPath)
    {

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        var mediaItem : MediaItem?
        
        if indexPath.section >= 0, indexPath.section < globals.display.section.indexes?.count {
            if let section = globals.display.section.indexes?[indexPath.section], let count = globals.display.mediaItems?.count {
                if (section + indexPath.row) >= 0,(section + indexPath.row) < count {
                    mediaItem = globals.display.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }

        return editActions(cell: nil, mediaItem: mediaItem) != nil
    }
    
    func editActions(cell: MediaTableViewCell?, mediaItem:MediaItem?) -> [AlertAction]?
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:editActions", completion: nil)
            return nil
        }

        // This casues a recursive loop on cellForRowAt indexPath
//        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
//            return nil
//        }
        
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        var tags:AlertAction!
        var download:AlertAction!
        var search:AlertAction!
        var transcript:AlertAction!
        var voiceBase:AlertAction!
        var words:AlertAction!
        var scripture:AlertAction!
        
        var actions = [AlertAction]()
        
        tags = AlertAction(title: Constants.Strings.Tags, style: .default) {
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.

                navigationController.popoverPresentationController?.delegate = self

                navigationController.popoverPresentationController?.barButtonItem = self.tagsButton
                navigationController.popoverPresentationController?.permittedArrowDirections = .up

                popover.navigationItem.title = Constants.Strings.Show // Show MediaItems Tagged With
                
                popover.delegate = self
                popover.purpose = .selectingTags
                
                popover.stringSelected = globals.media.tags.selected ?? Constants.Strings.All

                popover.section.strings = mediaItem.tagsArray
                popover.section.strings?.insert(Constants.Strings.All,at: 0)
                
                popover.vc = self
                
                self.present(navigationController, animated: true, completion: nil)
            }
        }
        
        if mediaItem.hasAudio, let state = mediaItem.audioDownload?.state {
            var title = ""
            var style = UIAlertActionStyle.default
            
            switch state {
            case .none:
                title = Constants.Strings.Download_Audio
                break
                
            case .downloading:
                title = Constants.Strings.Cancel_Audio_Download
                break
            case .downloaded:
                title = Constants.Strings.Delete_Audio_Download
                style = UIAlertActionStyle.destructive
                break
            }
            
            download = AlertAction(title: title, style: style, action: {
                switch title {
                case Constants.Strings.Download_Audio:
                    mediaItem.audioDownload?.download()
                    Thread.onMainThread(block: {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: mediaItem.audioDownload)
                    })
                    break
                    
                case Constants.Strings.Delete_Audio_Download:
                    let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                    message: nil,
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                        (action : UIAlertAction!) -> Void in
                        mediaItem.audioDownload?.delete()
                    })
                    alert.addAction(yesAction)
                    
                    let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(noAction)
                    
                    let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                case Constants.Strings.Cancel_Audio_Download:
                    if let state = mediaItem.audioDownload?.state {
                        switch state {
                        case .downloading:
                            mediaItem.audioDownload?.cancel()
                            break
                            
                        case .downloaded:
                            let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                            message: nil,
                                                            preferredStyle: .alert)
                            alert.makeOpaque()
                            
                            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                                (action : UIAlertAction!) -> Void in
                                mediaItem.audioDownload?.delete()
                            })
                            alert.addAction(yesAction)
                            
                            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                                (action : UIAlertAction!) -> Void in
                                
                            })
                            alert.addAction(noAction)
                            
                            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                                (action : UIAlertAction!) -> Void in
                                
                            })
                            alert.addAction(cancel)
                            
                            self.present(alert, animated: true, completion: nil)
                            break
                            
                        default:
                            break
                        }
                    }
                    break
                    
                default:
                    break
                }
            })
        }
        
        search = AlertAction(title: Constants.Strings.Search, style: .default) {
            if let searchStrings = mediaItem.searchStrings(),
                let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: {
                    self.presentingVC = nil
                })
                
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.

                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.sourceView = self.view
                navigationController.popoverPresentationController?.sourceRect = self.searchBar.frame

                popover.navigationItem.title = Constants.Strings.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.section.strings = searchStrings
                
                popover.vc = self.splitViewController
                
                self.present(navigationController, animated: true, completion:{
                    self.presentingVC = navigationController
                })
            }
        }
        
        func transcriptTokens()
        {
            guard Thread.isMainThread else {
                alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:transcriptTokens", completion: nil)
                return
            }

            guard let tokens = mediaItem.notesTokens?.map({ (string:String,count:Int) -> String in
                return "\(string) (\(count))"
            }).sorted() else {
                networkUnavailable(self,"HTML transcript vocabulary unavailable.")
                return
            }
        
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: {
                    self.presentingVC = nil
                })
                
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationItem.title = Constants.Strings.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.parser = { (string:String) -> [String] in
                    return [string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)]
                }
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.section.showIndex = true
                
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
        
        words = AlertAction(title: Constants.Strings.Words, style: .default) {
            if mediaItem.hasNotesHTML {
                if mediaItem.notesTokens == nil {
                    guard globals.reachability.isReachable else {
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
        
        transcript = AlertAction(title: Constants.Strings.Transcript, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0]
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                if globals.search.valid && globals.search.transcripts {
                    htmlString = mediaItem.markedFullNotesHTML(searchText:globals.search.text, wholeWordsOnly: false, index: true)
                } else {
                    htmlString = mediaItem.fullNotesHTML
                }
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                guard globals.reachability.isReachable else {
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
                })
            }
        }
        
        voiceBase = AlertAction(title: "VoiceBase", style: .default) {
            var alertActions = [AlertAction]()
            
            if let actions = mediaItem.audioTranscript?.recognizeAlertActions(viewController:self,tableView:self.tableView) {
                alertActions.append(actions)
            }
            if let actions = mediaItem.videoTranscript?.recognizeAlertActions(viewController:self,tableView:self.tableView) {
                alertActions.append(actions)
            }
            
            alertActionsCancel( viewController: self,
                                title: "VoiceBase",
                                message: "Machine Generated Transcript",
                                alertActions: alertActions,
                                cancelAction: nil)
        }
        
        scripture = AlertAction(title: Constants.Strings.Scripture, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0]
            
            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    guard globals.reachability.isReachable else {
                        networkUnavailable(self,"Scripture text unavailable.")
                        return
                    }

                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.loadJSON()
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable(self,"Scripture text unavailable.")
                        }
                    })
                }
            }
        }

        if mediaItem.books != nil {
            actions.append(scripture)
        }

        if mediaItem.hasTags {
            actions.append(tags)
        }
        actions.append(search)
        
        if mediaItem.hasNotesHTML {
            actions.append(words)
            actions.append(transcript)
        }
        
        if mediaItem.hasAudio && (download != nil) {
            actions.append(download)
        }
        
        if globals.allowMGTs {
            actions.append(voiceBase)
        }
    
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
            //            return editActions(cell: cell, mediaItem: cell.mediaItem)
            
            let action = UITableViewRowAction(style: .normal, title: "Actions") { rowAction, indexPath in
                let alert = UIAlertController(  title: "Actions",
                                                message: message,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                if let alertActions = self.editActions(cell: cell, mediaItem: cell.mediaItem) {
                    for alertAction in alertActions {
                        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                            alertAction.action?()
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
