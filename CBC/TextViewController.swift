//
//  TextViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/8/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension TextViewController: UISearchBarDelegate
{
    //MARK: SearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard self.isViewLoaded else {
            return false
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBarShouldBeginEditing",completion:nil)
            return false
        }
        
        searchBar.showsCancelButton = true
        
        if !searchActive {
            searchBar.text = nil
        }
        
        searchQueue.cancelAllOperations()
        
//        let searchOp = CancelableOperation { (test:(()->Bool)?) in
        searchQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            let text = self?.changedText?.markedBySearch(searchText: self?.searchText, wholeWordsOnly: false, test: test)
            
            Thread.onMain {
                self?.textView.attributedText = text
            }
        }
        
//        searchQueue.addOperation(searchOp)
        
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
        if searchBar.text?.isEmpty == true {
            searchActive = false
            searchBar.showsCancelButton = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        self.searchText = searchText

        startSearch(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchText = searchBar.text
        
        searchQueue.cancelAllOperations()

//        let searchOp = CancelableOperation { (test:(()->Bool)?) in
        searchQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            let text = self?.changedText?.markedBySearch(searchText: self?.searchText, wholeWordsOnly: false, test: test)
            
            Thread.onMain {
                self?.textView.attributedText = text
                
                if let lastRange = self?.lastRange, let endIndex = self?.textView.attributedText.string.endIndex {
                    let startingRange = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: endIndex))
                    
                    if let searchText = self?.searchText,let range = self?.textView.attributedText.string.lowercased().range(of: searchText.lowercased(), options: [], range: startingRange, locale: nil) {
                        self?.textView.scrollRangeToVisible(range)
                        self?.lastRange = range
                    } else {
                        self?.lastRange = nil
                    }
                }
                
                if self?.lastRange == nil {
                    if let searchText = self?.searchText,let range = self?.textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
                        self?.textView.scrollRangeToVisible(range)
                        self?.lastRange = range
                    } else {
                        Alerts.shared.alert(title: "Not Found", message: "")
                    }
                }
            }
        }
        
//        searchQueue.addOperation(searchOp)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false
        
        if let changedText = changedText {
            searchQueue.cancelAllOperations()
            
            let text = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.body)
            
            searchQueue.addOperation {
                Thread.onMain {
                    self.textView.attributedText = text
                }
            }
        }
        
        searchBar.showsCancelButton = false
        
        searchBar.resignFirstResponder()
        searchBar.text = nil
    }
}

extension TextViewController : UIScrollViewDelegate
{
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {

    }
}

extension TextViewController : UITextViewDelegate
{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        guard !readOnly else {
            return false
        }
        
        // Asks the delegate if editing should begin in the specified text view.
        guard !isTracking else {
            return false
        }
        
        if searchActive {
            searchActive = false
        }
        
        if let changedText = changedText, self.textView.attributedText != NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.body) {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.body)
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has begun.
        
        editingActive = true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should stop in the specified text view.
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has ended.

        editingActive = false
    }
    
    func textView(_ shouldChangeTextIn: NSRange, replacementText: String)
    {
        // Asks the delegate whether the specified text should be replaced in the text view.

    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // Tells the delegate that the text or attributes in the specified text view were changed by the user.
    
        // Hopefully this isn't expensive
        changedText = textView.attributedText.string
    }
    
    func textViewDidChangeSelection(_ textView: UITextView)
    {
        // Tells the delegate that the text selection changed in the specified text view.
        
    }
}

extension TextViewController : PopoverPickerControllerDelegate
{
    func stringPicked(_ string: String?, purpose:PopoverPurpose?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaViewController:stringPicked", completion: nil)
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let string = string else {
            return
        }
        
        guard let purpose = purpose else {
            return
        }
        
        switch purpose {
        case .selectingWord:
            let searchText = string.word ?? string
            
            self.searchActive = true
            self.searchText = searchText
            
            self.searchBar.text = searchText
            
            self.searchBar.becomeFirstResponder()
            
            startSearch(searchText)
            break
            
        case .selectingGapTime:
            let gapThreashold = Double(string)
            
            let text = self.textView.attributedText.string
            
            if let words = self.wordRangeTiming?.cache?.sorted(by: { (first, second) -> Bool in
                if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                    return first > second
                }
                
                return first["gap"] != nil
            }) {
                func makeVisible(showGapTimes:Bool)
                {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                        // test:(()->(Bool))?
                        self.process(work: { [weak self] () -> (Any?) in
                            self?.addParagraphBreaks(   interactive:false, makeVisible:true, showGapTimes:showGapTimes,                                            gapThreshold:gapThreashold, words:words, text:text,
                                                        completion: { (string:String?) -> (Void) in
                                                            self?.updateBarButtons()
                                                            self?.changedText = string
                                                            if let string = string {
                                                                Thread.onMain {
                                                                    self?.textView.attributedText = NSMutableAttributedString(string:string, attributes:Constants.Fonts.Attributes.body)
                                                                }
                                                            }
                                                        })
                            
                            self?.editingQueue.waitUntilAllOperationsAreFinished()
                            
                            return nil
                        }) { [weak self] (data:Any?) in
                            self?.updateBarButtons()
                        }
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                        // test:(()->(Bool))?
                        self.process(work: { [weak self] () -> (Any?) in
                            self?.addParagraphBreaks(   interactive:false, makeVisible:false, showGapTimes:showGapTimes,                                           gapThreshold:gapThreashold, words:words, text:text,
                                                        completion: { (string:String?) -> (Void) in
                                                            self?.updateBarButtons()
                                                            self?.changedText = string
                                                            if let string = string {
                                                                Thread.onMain {
                                                                    self?.textView.attributedText = NSMutableAttributedString(string:string, attributes:Constants.Fonts.Attributes.body)
                                                                }
                                                            }
                                                        })
                            
                            self?.editingQueue.waitUntilAllOperationsAreFinished()
                            
                            return nil
                        }) { [weak self] (data:Any?) in
                            self?.updateBarButtons()
                        }
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                    
                    Alerts.shared.alert(title:"Make Changes Visible?", message:nil, actions:actions)
                }
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                    makeVisible(showGapTimes:true)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                    makeVisible(showGapTimes:false)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                
                Alerts.shared.alert(title:"Show Gap Times?", message:nil, actions:actions)
            }
            break
            
        default:
            break
        }
    }
}

extension TextViewController : UIActivityItemSource
{
    @objc func share()
    {
        guard let text = textView.text else {
            return
        }
        
        // Must be on main thread.
        let print = UISimpleTextPrintFormatter(text: text)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = CBCActivityViewController(activityItems:[print,text,self] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ]
        
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        // present the view controller
        Alerts.shared.blockPresent(presenting: self, presented: activityViewController, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivity.ActivityType] = [.message, .mail,.print,.openInIBooks]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        guard let activityType = activityType else {
            return nil
        }
        
        guard let text = textView.text else {
            return nil
        }
        
        if #available(iOS 11.0, *) {
            TextViewController.cases.append(.markupAsPDF)
        }
        
        if TextViewController.cases.contains(activityType) {
            return text
        } else {
            return text
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return transcript?.mediaItem?.text?.singleLine ?? (self.navigationItem.title ?? "")
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        guard let activityType = activityType else {
            return "public.plain-text"
        }
        
        if WebViewController.cases.contains(activityType) {
            return "public.text"
        } else {
            return "public.plain-text"
        }
    }
}

extension TextViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return nil
    }
    
    func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "TextViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        
        let string = strings[index]
        
        switch purpose {
        case .selectingWord:
            popover?["WORD"]?.dismiss(animated: true, completion: nil)

            let searchText = string.word ?? string

            self.searchActive = true
            self.searchText = searchText
            
            self.searchBar.text = searchText
            
            self.searchBar.becomeFirstResponder()
            
            startSearch(searchText)
            break
            
        case .selectingAction:
            popover?["ACTION"]?.dismiss(animated: true, completion: nil)
            
            switch string {
            case Constants.Strings.Full_Screen:
                showFullScreen()
                break
                
            case Constants.Strings.Print:
                self.printText(string: self.textView.text)
                break
                
            case Constants.Strings.Share:
                share()
                break
                
            case Constants.Strings.Word_Picker:
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = self
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.delegate = self
                    
                    popover.allowsSelection = search
                    
                    popover.purpose = .selectingWord
                    
                    if let mediaItem = mediaItem {
                        popover.navigationItem.title = mediaItem.title
                        
                        popover.stringsFunction = {
                            if let keys = mediaItem.notesTokens?.result?.keys {
                                let strings = [String](keys).sorted()
                                return strings
                            }
                            
                            return nil
                        }
                    } else
                        
                    if let transcript = transcript {
                        popover.navigationItem.title = transcript.mediaItem?.title
                        
                        popover.stringsFunction = {
                            // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                            return transcript.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                                return word
                            }).sorted()
                        }
                    } else {
                        popover.navigationItem.title = navigationItem.title
                        
                        let text = self.textView.text
                        
                        popover.stringsFunction = {
                            // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                            return text?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                                return word
                            }).sorted()
                        }
                    }
                    
                    present(navigationController, animated: true, completion: nil)
                }
                break
                
            case Constants.Strings.Word_Cloud:
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WORD_CLOUD) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? CloudViewController {
                    navigationController.modalPresentationStyle = .fullScreen
                    
                    navigationController.popoverPresentationController?.delegate = self
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.cloudTitle = navigationItem.title

                    let string = textView.text

                    popover.cloudString = string
                    
                    popover.cloudWordDictsFunction = {
                        let words:[[String:Any]]? = string?.tokensAndCounts?.map({ (key:String, value:Int) -> [String:Any] in
                            return ["word":key,"count":value,"selected":true]
                        })
                        
                        return words
                    }
                    
                    popover.cloudFont = UIFont.preferredFont(forTextStyle:.body)
                    
                    present(navigationController, animated: true, completion:  nil)
                }
                break
                
            case Constants.Strings.Word_Index:
                if let mediaItem = mediaItem, mediaItem.hasNotesText {
                    self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                        return mediaItem.notesTokens?.result?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted().tableHTML(title:mediaItem.title, test:test)
                    }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                        self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: Constants.Strings.Word_Index, htmlString: data as? String)
                        self?.updateBarButtons()
                    })
                } else
                if let transcript = transcript {
                    self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                        return transcript.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                            return "\(word) (\(count))"
                        }).sorted().tableHTML(title:transcript.title,test:test)
                    }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                        self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: Constants.Strings.Word_Index, htmlString: data as? String)
                        self?.updateBarButtons()
                    })
                } else {
                    self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                        return self?.textView.text?.tokensAndCounts?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted().tableHTML(test:test)
                    }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                        self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: Constants.Strings.Word_Index, htmlString: data as? String)
                        self?.updateBarButtons()
                    })
                }
                break
                
            case Constants.Strings.Words:
                if let mediaItem = mediaItem, mediaItem.hasNotesText {
                    self.selectWord(title:mediaItem.title, purpose:.selectingWord, allowsSelection:false, stringsFunction: { [weak self] in
                        return mediaItem.notesTokens?.result?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    }) { (popover:PopoverTableViewController) in
                        popover.selectedMediaItem = mediaItem
                    }
                } else
                if let transcript = transcript {
                    self.selectWord(title:transcript.mediaItem?.title, purpose:.selectingWord, allowsSelection:false, stringsFunction: { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return transcript.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                            return "\(word) (\(count))"
                        }).sorted()
                    })
                } else {
                    self.selectWord(title:navigationItem.title, purpose:.selectingWord, allowsSelection:false, stringsFunction: { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return self?.textView.text?.tokensAndCounts?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    })
                }
                
            case Constants.Strings.Word_Search:
                if let mediaItem = mediaItem, mediaItem.hasNotesText {
                    self.selectWord(title:mediaItem.title, purpose:.selectingWord, stringsFunction: { [weak self] in
                        return mediaItem.notesTokens?.result?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    }) { (popover:PopoverTableViewController) in
                        popover.selectedMediaItem = mediaItem
                    }
                } else
                if let transcript = transcript {
                    self.selectWord(title:transcript.mediaItem?.title, purpose:.selectingWord, stringsFunction: { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return transcript.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                            return "\(word) (\(count))"
                        }).sorted()
                    })
                } else {
                    self.selectWord(title:navigationItem.title, purpose:.selectingWord, stringsFunction: { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return self?.textView.text?.tokensAndCounts?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    })
                }
                break
                
            case Constants.Strings.Email_One:
                if let title = navigationItem.title, let string = textView.text {
                    mailText(viewController: self, to: [], subject: Constants.CBC.LONG + Constants.SINGLE_SPACE + title, body: string)
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

/**
 For editing transcripts.
 */

class TextViewController : CBCViewController
{
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()
    
    var lastRange : Range<String.Index>?
    
    var text : String?
    {
        didSet {
            changedText = text
        }
    }
    
    var changedText : String?
    {
        didSet {
            if isViewLoaded {
                updateBarButtons()
            }
        }
    }
    
    func updatePlayPauseButton()
    {
        Thread.onMain {
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .playing:
                    self.playPauseButton?.title = "Pause"
                    
                default:
                    self.playPauseButton?.title = "Play"
                    break
                }
            }
        }
    }
    
    func updateSaveCancelButtons()
    {
        Thread.onMain {
            if let changedText = self.changedText, let text = self.text, changedText != text {
                print(prettyFirstDifferenceBetweenStrings(changedText as NSString, text as NSString))
                
                if !self.readOnly {
                    self.saveButton?.isEnabled = self.cancelButton?.isEnabled ?? false
                    self.cancelButton?.title = "Cancel"
                } else {
                    self.saveButton?.isEnabled = false
                    self.cancelButton?.title = "Done"
                }
            } else {
                self.saveButton?.isEnabled = false
                self.cancelButton?.title = "Done"
            }
        }
    }
    
    func updateSyncButton()
    {
        Thread.onMain {
            if self.isTracking {
                self.syncButton?.title = "Stop Sync"
            } else {
                self.syncButton?.title = "Sync"
            }
        }
    }
    
    func updateBarButtons()
    {
        updatePlayPauseButton()
        
        updateSaveCancelButtons()

        updateSyncButton()
    }
    
    var readOnly = false
    var notifyReadOnly = false

    var searchText : String?

    var search = false
    
    var fullScreenButton : UIBarButtonItem!
    var syncButton : UIBarButtonItem!
    var playPauseButton : UIBarButtonItem!
    
    func disableToolBarButtons()
    {
        Thread.onMain {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = false
                }
            }
        }
    }
    
    func disableBarButtons()
    {
        Thread.onMain {
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
        Thread.onMain {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMain {
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
            
            self.updateBarButtons()
        }
        
        enableToolBarButtons()
    }

    var searchActive = false
    {
        didSet {
            guard searchActive != oldValue else {
                return
            }

            assistButton.isEnabled = !searchActive
            syncButton.isEnabled = !searchActive

            if searchActive {
                oldRange = nil
            } else {

            }

            if !searchActive {
                searchBar.text = nil
                searchBar.showsCancelButton = false
            }
        }
    }
    
    var wholeWordsOnly = false
    var searchInteractive = true

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    var editingActive = false
    {
        didSet {
            guard editingActive != oldValue else {
                return
            }
            
            assistButton.isEnabled = !editingActive
            syncButton.isEnabled = !editingActive

            if editingActive {
                oldRange = nil
                
                navigationItem.rightBarButtonItems?.append(dismissButton)
            } else {
                navigationItem.rightBarButtonItems?.removeLast()
            }
        }
    }

    @IBOutlet weak var textViewToTop: NSLayoutConstraint!
    
    var automatic = false
    var automaticVisible = false
    var automaticInteractive = false
    var automaticCompletion : (()->(Void))?
    
    var onDone : ((String)->(Void))?
    var onSave : ((String)->(Void))?
    var onCancel : (()->(Void))?

    @objc func singleTapAction(_ tap:UITapGestureRecognizer)
    {
        guard isTracking else {
            return
        }
        
        let pos = tap.location(in: textView)
        
        let tapPos = textView.closestPosition(to: pos)
        
        if isTracking, let wordRangeTiming = wordRangeTiming?.cache, let tapPos = tapPos {
            let range = Range(uncheckedBounds: (lower: textView.offset(from: textView.beginningOfDocument, to: tapPos), upper: textView.offset(from: textView.beginningOfDocument, to: tapPos)))
            
            var closest : [String:Any]?
            var minDistance : Int?
            
            for wordRangeTime in wordRangeTiming {
                if  let lowerBound = wordRangeTime["lowerBound"] as? Int,
                    let upperBound = wordRangeTime["upperBound"] as? Int {
                    if (range.lowerBound >= lowerBound) && (range.upperBound <= upperBound) {
                        closest = wordRangeTime
                        break
                    }
                    
                    var distance = 0
                    
                    if range.lowerBound < lowerBound {
                        distance = lowerBound - range.lowerBound
                    }
                    
                    if range.upperBound > upperBound {
                        distance = range.upperBound - upperBound
                    }
                    
                    if (minDistance == nil) || (distance < minDistance) {
                        minDistance = distance
                        closest = wordRangeTime
                    }
                }
            }
            
            if let segment = closest {
                if (oldTextRange == nil) || (oldTextRange != range) {
                    if  let start = segment["start"] as? Double,
                        let end = segment["end"] as? Double,
                        let lowerBound = segment["lowerBound"] as? Int,
                        let upperBound = segment["upperBound"] as? Int {
                        let ratio = Double(range.lowerBound - lowerBound)/Double(upperBound - lowerBound)
                        Globals.shared.mediaPlayer.seek(to: start + (ratio * (end - start)))
                    }
                }
                
                if oldTextRange != range {
                    oldTextRange = range
                }
            }
        }
    }
    
    var singleTap : UITapGestureRecognizer!
    
    @IBOutlet weak var textView: UITextView!
    {
        didSet {
            textView.autocorrectionType = .no
            
            singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(_:)))
            singleTap.numberOfTapsRequired = 1
            textView.addGestureRecognizer(singleTap)
            singleTap.isEnabled = false
        }
    }
    
    var transcript:VoiceBase?
    
    lazy var wordRangeTiming : Fetch<[[String:Any]]>? = { [weak self] in
        let fetch = Fetch<[[String:Any]]>(name: "WordRangeTiming") // Assumes there is only one at a time globally.
        
        fetch.fetch = {
            // Not interruptable until wordRangeTiming is.
            return self?.transcript?.wordRangeTiming
        }
        
        fetch.didSet = { (array:[[String:Any]]?) in
            if fetch.cache != nil {
                self?.checkSync()
            }
            Thread.onMain {
                self?.syncButton?.isEnabled = self?.wordRangeTiming != nil
                self?.activityIndicator?.stopAnimating()
            }
        }

        return fetch
    }()
    
    var oldRange : Range<String.Index>?

    func removeAssist()
    {
        guard assist else {
            return
        }
        
        assistButton?.isEnabled = false
    }
    
    func restoreAssist()
    {
        guard assist else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        assistButton?.isEnabled = true
    }
    
    func removeTracking()
    {
        guard track else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        wasTracking = isTracking
        
        wasPlaying = Globals.shared.mediaPlayer.isPlaying
        
        isTracking = false
        stopTracking()
    }
    
    func restoreTracking()
    {
        guard track else {
            return
        }
        
        isTracking = wasTracking ?? true
        wasTracking = nil
        
        if isTracking {
            startTracking()
        }

        syncButton.isEnabled = true
        
        if wordRangeTiming == nil {
            activityIndicator.startAnimating()
        }
    }
    
    func stopTracking()
    {
        guard track else {
            return
        }
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        if let changedText = changedText {
            textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.body)
        }
    }
    
    func startTracking()
    {
        guard track else {
            return
        }
        
        if trackingTimer == nil {
            trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(follow), userInfo: nil, repeats: true)
        } else {
            print("ERROR: trackingTimer not NIL!")
        }
    }
    
    var oldTextRange : Range<Int>? // UITextRange?
    
    @objc func follow()
    {
        guard !searchActive else {
            return
        }
        
        guard !editingActive else {
            return
        }
        
        guard let wordRangeTiming = wordRangeTiming?.cache else {
            return
        }
        
        if let seconds = Globals.shared.mediaPlayer.currentTime?.seconds {
            var index = 0
            
            for element in wordRangeTiming {
                if let startTime = element["start"] as? Double {
                    if seconds < startTime {
                        break
                    }
                }
                
                index += 1
            }
            index -= 1
            
            index = max(index,0)
            
            if let range = wordRangeTiming[index]["range"] as? Range<String.Index> {
                if let changedText = changedText, range != oldRange {
                    let before = String(changedText[..<range.lowerBound])
                    let text = String(changedText[range])
                    let after = String(changedText[range.upperBound...])
                    let beforeAttr = NSMutableAttributedString(string: before, attributes: Constants.Fonts.Attributes.body)
                    let textAttr = NSMutableAttributedString(string: text, attributes: Constants.Fonts.Attributes.marked)
                    let afterAttr = NSMutableAttributedString(string: after, attributes: Constants.Fonts.Attributes.body)
                    
                    beforeAttr.append(textAttr)
                    beforeAttr.append(afterAttr)
                    
                    textView.attributedText = beforeAttr
                    
                    textView.scrollRangeToVisible(range)
                    
                    oldRange = range
                } else {
                    // Annoying to scroll to range when not playing.
                }
            } else {
                if let text = wordRangeTiming[index]["text"] {
                    print("RANGE NOT FOUND: ",text)
                } else {
                    print("RANGE NOT FOUND")
                }
            }
        }
    }
    
    var wasTracking : Bool?
    var wasPlaying : Bool?
    
    @objc func tracking()
    {
        isTracking = !isTracking
    }
    
    var track = false
    {
        didSet {

        }
    }
    
    var isTracking = false
    {
        didSet {
            singleTap?.isEnabled = isTracking
            
            if isTracking != oldValue {
                if !isTracking {
                    oldRange = nil
                    syncButton.title = "Sync"
                    stopTracking()
                    restoreAssist()
                }
                
                if isTracking {
                    syncButton.title = "Stop Sync"
                    startTracking()
                    removeAssist()
                }
            }
        }
    }
    
    var trackingTimer : Timer?

    var assist = false

    @objc func save()
    {
        // DOES NOT DISMISS THE DIALOG
        self.onSave?(self.textView.attributedText.string)
        text = changedText
    }
    
    @objc func cancel()
    {
        guard let title = cancelButton.title else {
            return
        }
        
        // DISMISSES THE DIALOG
        switch title {
        case "Done":
            // Can't get here if the text is changed unless it is readOnly or save has been tapped.
            if isTracking {
                stopTracking()
            }
            dismiss(animated: true, completion: {
                self.onDone?(self.textView.attributedText.string)
            })

        case "Cancel":
            self.yesOrNo(title: "Discard Changes?", message: nil, yesAction: { () -> (Void) in
                self.dismiss(animated: true, completion: {
                    if self.isTracking {
                        self.stopTracking()
                    }
                    self.onCancel?()
                })
            }, yesStyle: .default, noAction: nil, noStyle: .default)

        default:
            break
        }
    }
    
    private lazy var editingQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "TEVC:Editing" // Implies there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    private lazy var searchQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "TEVC:Search" // Implies there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        searchQueue.cancelAllOperations()
        editingQueue.cancelAllOperations()
//        operationQueue.cancelAllOperations()
    }
    
    func startSearch(_ searchText:String?)
    {
        guard let searchText = searchText else {
            return
        }
        
        searchQueue.cancelAllOperations()
        
//        let attributedText = self.textView.attributedText
        
//        let searchOp = CancelableOperation { (test:(()->Bool)?) in
        searchQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            let text = self?.changedText?.markedBySearch(searchText: searchText, wholeWordsOnly: false, test: test)
            
            Thread.onMain {
                self?.textView.attributedText = text
                
                if !searchText.isEmpty {
                    if let range = self?.textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
                        self?.textView.scrollRangeToVisible(range)
                        self?.lastRange = range
                    } else {
                        Alerts.shared.alert(title: "Not Found", message: "")
                    }
                }
            }
        }
        
//        searchQueue.addOperation(searchOp)
    }
    
    @objc func autoEdit()
    {
        guard !searchActive else {
            return
        }
        
        guard !editingActive else {
            return
        }
        
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, handler: { [weak self] in
            guard let vc = self else {
                return
            }

            if  let transcriptString = self?.textView.attributedText.string.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                let transcriptFromWordsString = self?.transcript?.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                transcriptString == transcriptFromWordsString {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Paragraph Breaks", style: .default, handler: { [weak self] in
                    //                    print(wordRangeTiming)
                    
//                    var speakerNotesParagraphWords : [String:Int]?

//                    var tooClose : Int?

                    let block = { (speakerNotesParagraphWords : [String:Int]?, tooClose : Int?) in
                        // clean this up so it doesn't use variables from outside its scope but parameters passed in?
                        // Multiply the gap time by the frequency of the word that appears after it and sort
                        // in descending order to suggest the most likely paragraph breaks.
                        
                        if let words = self?.wordRangeTiming?.cache?.sorted(by: { (first, second) -> Bool in
                            if let firstGap = first["gap"] as? Double, let secondGap = second["gap"] as? Double {
                                if let firstWord = first["text"] as? String, let secondWord = second["text"] as? String {
                                    return (firstGap * Double(speakerNotesParagraphWords?[firstWord.lowercased()] ?? 1)) > (secondGap * Double(speakerNotesParagraphWords?[secondWord.lowercased()] ?? 1))
                                }
                            }
                            
                            return first["gap"] != nil
                        }) {
                            let text = self?.textView.attributedText.string
                            
                            var actions = [AlertAction]()
                            
                            actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                                // test:(()->(Bool))?
                                vc.process(work: { [weak self] () -> (Any?) in
                                    self?.addParagraphBreaks(   interactive:true, makeVisible:false, showGapTimes:true,                                             tooClose:tooClose, words:words, text:text,
                                                                completion: { (string:String?) -> (Void) in
                                                                    self?.updateBarButtons()
                                                                    self?.changedText = string
                                                                    if let string = string {
                                                                        Thread.onMain {
                                                                            self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                                                                        }
                                                                    }
                                                                })

                                    return nil
                                }) { [weak self] (data:Any?) in
                                    self?.updateBarButtons()
                                }
                            }))
                            
                            actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                                // test:(()->(Bool))?
                                vc.process(work: { [weak self] () -> (Any?) in
                                    self?.addParagraphBreaks(   interactive:true, makeVisible:false, showGapTimes:false,                                            tooClose:tooClose, words:words, text:text,
                                                                completion: { (string:String?) -> (Void) in
                                                                    self?.updateBarButtons()
                                                                    self?.changedText = string
                                                                    if let string = string {
                                                                        Thread.onMain {
                                                                            self?.textView.attributedText = NSMutableAttributedString(string:string, attributes: Constants.Fonts.Attributes.body)
                                                                        }
                                                                    }
                                                                })

                                    return nil
                                }) { [weak self] (data:Any?) in
                                    self?.updateBarButtons()
                                }
                            }))
                            
                            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                                self?.updateBarButtons()
                            }))

                            Alerts.shared.alert(title:"Show Gap Times?", message:nil, actions:actions)
                        }
                    }

                    var alertActions = [AlertAction]()
                    alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                        // test:(()->(Bool))?
                        self?.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                            let speakerNotesParagraph = Globals.shared.media.repository.list?.filter({ (mediaItem:MediaItem) -> Bool in
                                mediaItem.speaker == self?.transcript?.mediaItem?.speaker // self?.mediaItem?.teacher?.name
                            }).speakerNotesParagraph
                            
                            speakerNotesParagraph?.lengths?.interrupt = test
                            let tooClose = speakerNotesParagraph?.overallAverageLength ?? 700 // default value is arbitrary - at best based on trial and error

                            speakerNotesParagraph?.words?.interrupt = test
                            let speakerNotesParagraphWords = speakerNotesParagraph?.words?.result
                            
                            self?.wordRangeTiming?.load() // ?? self?.transcript?.wordRangeTiming
                            
                            return (speakerNotesParagraphWords,tooClose)
                        }, completion: { (data:Any?,test:(()->(Bool))?) in
                            self?.updateBarButtons()
                            if test?() != true {
                                if let tuple = data as? ([String:Int]?, Int?) {
                                    block(tuple.0, tuple.1)
                                }
                            }
                        })
                    }))
                    alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: { () -> (Void) in
                        // test:(()->(Bool))?
                        self?.process(work: { [weak self] () -> (Any?) in
                            return self?.wordRangeTiming?.result
                        }, completion: { (data:Any?) in
                            self?.updateBarButtons()
                            block(nil,nil)
                        })
                    }))
                    alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: { () -> (Void) in
                        self?.updateBarButtons()
                    }))
                    Alerts.shared.alert(title: "Use Speaker Paragraph Words?", message: "Please note that this may take a considerable amount of time.", actions: alertActions)
                }))
                
                actions.append(AlertAction(title: "Text Edits", style: .default, handler: { [weak self] in
                    guard let text = self?.textView.attributedText.string else {
                        return
                    }

                    // USE PROCESS TO SHOW SPINNER UNTIL FIRST CHANGE FOUND!
                    
                    // test:(()->(Bool))?
                    vc.process(work: { [weak self] () -> (Any?) in
                        guard let changes = self?.transcript?.changes(interactive:true, longFormat:false) else {
                            return nil
                        }
                        
                        self?.changeText(interactive: true, makeVisible:false, text: text, startingRange: nil, changes: changes, completion: { (string:String) -> (Void) in
                            self?.updateBarButtons()
                            self?.changedText = string
                            Thread.onMain {
                                self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                            }
                        })
                        
                        self?.editingQueue.waitUntilAllOperationsAreFinished()
                        
                        return nil
                    }) { [weak self] (data:Any?) in
                        self?.updateBarButtons()
                    }
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                    self?.updateBarButtons()
                }))
                
                vc.alert(title:"Suggest",message:"Because it relies upon the original text and timing information from the transcription, Paragraph Breaks should be done first before any other editing is done.",actions:actions)
            } else {
                guard let text = self?.textView.attributedText.string else {
                    return
                }
                
                // USE PROCESS TO SHOW THE USER A SPINNER UNTIL THE FIRST CHANGE IS FOUND!
                
                // test:(()->(Bool))?
                vc.process(work: { [weak self] () -> (Any?) in
                    guard let changes = self?.transcript?.changes(interactive:true, longFormat:false) else {
                        return nil
                    }
                    
                    self?.changeText(interactive: true, makeVisible:false, text: text, startingRange: nil, changes: changes, completion: { (string:String) -> (Void) in
                        self?.updateBarButtons()
                        self?.changedText = string
                        Thread.onMain {
                            self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                        }
                    })

                    self?.editingQueue.waitUntilAllOperationsAreFinished()
                    
                    return nil
                }) { [weak self] (data:Any?) in
                    self?.updateBarButtons()
                }
            }
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, handler: { [weak self] in
            guard let vc = self else {
                return
            }
            
            if  let transcriptString = self?.textView.attributedText.string.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                let transcriptFromWordsString = self?.transcript?.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                transcriptString == transcriptFromWordsString {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Paragraph Breaks", style: .default, handler: { [weak self] in
//                    var speakerNotesParagraphWords : [String:Int]?
//
//                    var tooClose : Int?
                    
                    let block = { (speakerNotesParagraphWords : [String:Int]?, tooClose : Int?) in
                        // Multiply the gap time by the frequency of the word that appears after it and sort
                        // in descending order to suggest the most likely paragraph breaks.
                        
                        if let words = self?.wordRangeTiming?.cache?.sorted(by: { (first, second) -> Bool in
                            if let firstGap = first["gap"] as? Double, let secondGap = second["gap"] as? Double {
                                if let firstWord = first["text"] as? String, let secondWord = second["text"] as? String {
                                    return (firstGap * Double(speakerNotesParagraphWords?[firstWord.lowercased()] ?? 1)) > (secondGap * Double(speakerNotesParagraphWords?[secondWord.lowercased()] ?? 1))
                                }
                            }
                            
                            return first["gap"] != nil
                        }) {
                            guard speakerNotesParagraphWords != nil else {
                                if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                                    let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                                    guard let vc = self else {
                                        return
                                    }
                                    
                                    navigationController.modalPresentationStyle = .overCurrentContext
                                    
                                    navigationController.popoverPresentationController?.delegate = vc
                                    
                                    popover.navigationController?.isNavigationBarHidden = false
                                    
                                    popover.navigationItem.title = "Select Gap Threshold"
                                    
                                    popover.delegate = vc

                                    popover.purpose = .selectingGapTime
                                    
                                    popover.barButtonActionTitle = "Show"
                                    popover.barButtonAction = { [weak popover] (gapThresholdString:String?) in
                                        guard let gapThresholdString = gapThresholdString, let gapThreshold = Double(gapThresholdString) else {
                                            return
                                        }
                                        
                                        // test:(()->(Bool))?
                                        popover?.process(work: { () -> (Any?) in
                                            guard var words = self?.wordRangeTiming?.cache?.sorted(by: { (first, second) -> Bool in
                                                if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                                                    return first > second
                                                }
                                                
                                                return first["gap"] != nil
                                            }), words.count > 0, var newText = self?.text else {
                                                return nil
                                            }
                                            
                                            repeat {
                                                let first = words.removeFirst()
                                                
                                                guard let range = first["range"] as? Range<String.Index> else {
                                                    continue
                                                }
                                                
                                                guard let gap = first["gap"] as? Double else {
                                                    continue
                                                }
                                                
                                                if gap >= gapThreshold {
                                                    let gapString = " <\(gap)><br/><br/>"
                                                    
                                                    newText.insert(contentsOf:gapString, at: range.lowerBound)
                                                    
                                                    for i in 0..<words.count {
                                                        if let wordRange = words[i]["range"] as? Range<String.Index> {
                                                            if wordRange.lowerBound > range.lowerBound {
                                                                var lower : String.Index?
                                                                var upper : String.Index?
                                                                
                                                                if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                                                    lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                                                                }
                                                                
                                                                if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                                                    upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                                                                }
                                                                
                                                                if let lower = lower, let upper = upper {
                                                                    let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                                                                    words[i]["range"] = newRange
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } while words.count > 0
                                            
                                            return newText
                                        }, completion: { (data:Any?) in
                                            guard var newText = data as? String else {
                                                return
                                            }
                                            
                                            if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                                                let webView = navigationController.viewControllers[0] as? WebViewController {
                                                navigationController.modalPresentationStyle = .overCurrentContext
                                                
                                                webView.search = false
                                                webView.content = .html
                                                
                                                newText = "<!DOCTYPE html><html><body>" + newText + "</body></html>"
                                                
                                                webView.html.string = newText.insertHead(fontSize: 24)
                                                
                                                Thread.onMain {
                                                    webView.navigationItem.title = self?.navigationItem.title
                                                    
                                                    popover?.present(navigationController, animated: true)
                                                }
                                            }
                                        })
                                    }
                                    
                                    popover.stringsFunction = {
                                        let gaps = words.map({ (dict) -> String in
                                            return (dict["gap"] as? Double)?.description ?? ""
                                        })
                                        
                                        return gaps
                                    }
                                    
                                    self?.present(navigationController, animated: true, completion: nil)
                                }
                                return
                            }

                            let text = self?.textView.attributedText.string
                            
                            func makeVisible(showGapTimes:Bool)
                            {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                                    // test:(()->(Bool))?
                                    self?.process(work: { [weak self] () -> (Any?) in
                                        self?.addParagraphBreaks(   interactive:false, makeVisible:true,
                                                                    showGapTimes:showGapTimes, gapThreshold:nil,
                                                                    tooClose:tooClose, words:words, text:text,
                                                                    completion: { (string:String?) -> (Void) in
                                                                        self?.updateBarButtons()
                                                                        self?.changedText = string
                                                                        if let string = string {
                                                                            Thread.onMain {
                                                                                self?.textView.attributedText = NSMutableAttributedString(string:string, attributes: Constants.Fonts.Attributes.body)
                                                                            }
                                                                        }
                                                                    })
                                        
                                        self?.editingQueue.waitUntilAllOperationsAreFinished()
                                        
                                        return nil
                                    }) { [weak self] (data:Any?) in
                                        self?.updateBarButtons()
                                    }
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                                    // test:(()->(Bool))?
                                    self?.process(work: { [weak self] () -> (Any?) in
                                        self?.addParagraphBreaks(   interactive:false, makeVisible:false,
                                                                    showGapTimes:showGapTimes, gapThreshold:nil,
                                                                    tooClose:tooClose, words:words, text:text,
                                                                    completion: { (string:String?) -> (Void) in
                                                                        self?.updateBarButtons()
                                                                        self?.changedText = string
                                                                        if let string = string {
                                                                            Thread.onMain {
                                                                                self?.textView.attributedText = NSMutableAttributedString(string:string, attributes: Constants.Fonts.Attributes.body)
                                                                            }
                                                                        }
                                                                    })
                                        
                                        self?.editingQueue.waitUntilAllOperationsAreFinished()
                                        
                                        return nil
                                    }) { [weak self] (data:Any?) in
                                        self?.updateBarButtons()
                                    }
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                                    self?.updateBarButtons()
                                }))
                                
                                Alerts.shared.alert(title:"Make Changes Visible?", message:nil, actions:actions)
                            }
                            
                            var actions = [AlertAction]()
                            
                            actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                                makeVisible(showGapTimes: true)
                            }))
                            
                            actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                                makeVisible(showGapTimes: false)
                            }))
                            
                            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                                self?.updateBarButtons()
                            }))
                            
                            Alerts.shared.alert(title:"Show Gap Times?", message:nil, actions:actions)
                        }
                    }
                    
                    var actions = [AlertAction]()
                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                        // test:(()->(Bool))?
                        self?.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                            let speakerNotesParagraph = Globals.shared.media.repository.list?.filter({ (mediaItem:MediaItem) -> Bool in
                                mediaItem.speaker == self?.transcript?.mediaItem?.speaker // self?.mediaItem?.teacher?.name
                            }).speakerNotesParagraph

                            speakerNotesParagraph?.lengths?.interrupt = test
                            let tooClose = speakerNotesParagraph?.overallAverageLength ?? 700 // default value is arbitrary - at best based on trial and error
                            
                            speakerNotesParagraph?.words?.interrupt = test
                            let speakerNotesParagraphWords = speakerNotesParagraph?.words?.result
                            
                            self?.wordRangeTiming?.load() // ?? self?.transcript?.wordRangeTiming
                            
                            return (speakerNotesParagraphWords,tooClose)
                        }, completion: { (data:Any?,test:(()->(Bool))?) in
                            self?.updateBarButtons()
                            if test?() != true {
                                if let tuple = data as? ([String:Int]?,Int?) {
                                    block(tuple.0,tuple.1)
                                }
                            }
                        })
                    }))
                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: { () -> (Void) in
                        // test:(()->(Bool))?
                        self?.process(work: { [weak self] () -> (Any?) in
                            return self?.wordRangeTiming?.result
                        }, completion: { (data:Any?) in
                            self?.updateBarButtons()
                            block(nil,nil)
                        })
                    }))
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: { () -> (Void) in
                        self?.updateBarButtons()
                    }))
                    Alerts.shared.alert(title:"Use Speaker Paragraph Words?", message: "Please note that this may take a considerable amount of time.", actions:actions)
                }))
                
                actions.append(AlertAction(title: "Text Edits", style: .default, handler: { [weak self] in
                    func makeVisible(_ makeVisible:Bool)
                    {
                        guard let text = self?.textView.attributedText.string else {
                            return
                        }
                        
                        // USING PROCESS BECAUSE WE ARE USING THE OPERATION QUEUE

                        // test:(()->(Bool))?
                        vc.process(work: { [weak self] () -> (Any?) in
                            guard let changes = self?.transcript?.changes(interactive:false, longFormat:false) else {
                                return nil
                            }
                            
                            self?.changeText(interactive: false, makeVisible:makeVisible, text:text, startingRange:nil, changes:changes, completion: { (string:String) -> (Void) in
                                self?.updateBarButtons()
                                self?.changedText = string
                                Thread.onMain {
                                    self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                                }
                            })
                            
                            self?.editingQueue.waitUntilAllOperationsAreFinished()
                            
                            return nil
                        }) { [weak self] (data:Any?) in
                            self?.updateBarButtons()
                        }
                    }

                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                        makeVisible(true)
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                        makeVisible(false)
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                    
                    Alerts.shared.alert(title:"Make Changes Visible?", message:nil, actions:actions)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                
                Alerts.shared.alert(title:"Perform",message:"Because it relies upon the original text and timing information from the transcription, Paragraph Breaks should be done first before any other editing is done.",actions:actions)
            } else {
                func makeVisible(_ makeVisible:Bool)
                {
                    guard let text = self?.textView.attributedText.string else {
                        return
                    }
                    
                    // USING PROCESS BECAUSE WE ARE USING THE OPERATION QUEUE
                    
                    // test:(()->(Bool))?
                    vc.process(work: { [weak self] () -> (Any?) in
                        guard let changes = self?.transcript?.changes(interactive:false, longFormat:false) else {
                            return nil
                        }
                        
                        self?.changeText(interactive: false, makeVisible:makeVisible, text:text, startingRange:nil, changes:changes, completion: { (string:String) -> (Void) in
                            self?.updateBarButtons()
                            self?.changedText = string
                            Thread.onMain {
                                self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                            }
                        })
                        
                        self?.editingQueue.waitUntilAllOperationsAreFinished()
                        
                        return nil
                    }) { [weak self] (data:Any?) in
                        self?.updateBarButtons()
                    }
                }
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: { () -> (Void) in
                    makeVisible(true)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:{
                    makeVisible(false)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                
                Alerts.shared.alert(title:"Make Changes Visible?", message:nil, actions:actions)
            }
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
        
        self.alert(title:"Start Assisted Editing?",message:nil,actions:actions)
    }

    var cancelButton : UIBarButtonItem!
    var saveButton : UIBarButtonItem!
    var assistButton : UIBarButtonItem!
    var dismissButton : UIBarButtonItem!

    var keyboardShowing = false
    var shrink:CGFloat = 0.0

    @objc func keyboardWillShow(_ notification: NSNotification)
    {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let kbdRect = CGRect(x: keyboardRect.minX, y: keyboardRect.minY - keyboardRect.height, width: keyboardRect.width, height: keyboardRect.height)
            let txtRect = textView.convert(textView.bounds, to: splitViewController?.view)
            let intersectRect = txtRect.intersection(kbdRect)
            
            if !keyboardShowing {
                // The toolbar and navBar are the same height.  Which should be deducted?  Why?  Why does this work?  Why is textView.bounds.minY not 0?
                
                if navigationController?.modalPresentationStyle == .formSheet {
                    shrink = intersectRect.height - (navigationController?.toolbar.frame.size.height ?? 0)
                } else {
                    shrink = intersectRect.height + 16
                }
                
                bottomLayoutConstraint.constant += shrink
            } else {
                if (intersectRect.height != shrink) {
                    let delta = shrink - intersectRect.height
                    shrink -= delta
                    if delta != 0 {
                        bottomLayoutConstraint.constant -= delta
                    }
                }
            }
        }

        view.layoutSubviews()
        
        keyboardShowing = true
    }

    @objc func keyboardWillHide(_ notification: NSNotification)
    {
        if keyboardShowing {
            bottomLayoutConstraint.constant -= shrink // textView.frame.size.height +
        }

        shrink = 0
        keyboardShowing = false
    }
    
    var activityIndicator : UIActivityIndicatorView!
    var activityBarButton : UIBarButtonItem!

    @objc func showFullScreen()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? TextViewController {
            dismiss(animated: false, completion: nil)
            
            navigationController.modalPresentationStyle = .overFullScreen
            
            popover.navigationItem.title = self.navigationItem.title

            popover.text = self.text
            popover.changedText = self.changedText

            popover.assist = self.assist
            popover.track = self.track
            popover.readOnly = self.readOnly

            // The full scren view will create its own trackingTime
//            popover.trackingTimer = self.trackingTimer

            popover.search = self.search
            popover.searchText = self.searchText
            popover.searchActive = self.searchActive
            popover.searchInteractive = self.searchInteractive
            
            popover.transcript = self.transcript

            popover.onSave = self.onSave
            popover.onCancel = self.onCancel
            popover.onDone = self.onDone

            popover.automatic = self.automatic
            popover.automaticCompletion = self.automaticCompletion
            popover.automaticInteractive = self.automaticInteractive

            popover.editingActive = self.editingActive
            
            popover.wordRangeTiming = self.wordRangeTiming
            
            popover.isTracking = self.isTracking
            
            popover.keyboardShowing = self.keyboardShowing
            popover.shrink = self.shrink

            popover.lastRange = self.lastRange

            // Don't
//            popover.operationQueue = self.operationQueue
            
            popover.oldRange = self.oldRange
            
            popover.wasPlaying = self.wasPlaying
            popover.wasTracking = self.wasTracking
            
            popover.wholeWordsOnly = self.wholeWordsOnly

            popover.navigationController?.isNavigationBarHidden = false
            
            self.presentingViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func playPause()
    {
        guard let title = playPauseButton.title else {
            return
        }
        
        switch title {
        case "Play":
            Globals.shared.mediaPlayer.play()
            playPauseButton.title = "Pause"
            
        case "Pause":
            Globals.shared.mediaPlayer.pause()
            playPauseButton.title = "Play"
            
        default:
            break
        }
    }
    
    @objc func dismissKeyboard()
    {
        textView.resignFirstResponder()
    }
    
    @objc func actionMenu()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            var actionMenu = [String]()
            
            if textView.text != nil {
                if search {
                    actionMenu.append(Constants.Strings.Word_Search)
                } else {
                    actionMenu.append(Constants.Strings.Words)
                }
                
                actionMenu.append(Constants.Strings.Word_Picker)

                actionMenu.append(Constants.Strings.Word_Index)

                if Globals.shared.splitViewController?.isCollapsed == false {
                    let vClass = Globals.shared.splitViewController?.traitCollection.verticalSizeClass
                    let hClass = Globals.shared.splitViewController?.traitCollection.horizontalSizeClass
                    
                    if vClass != .compact, hClass != .compact {
                        actionMenu.append(Constants.Strings.Word_Cloud)
                    }
                }
                
                actionMenu.append(Constants.Strings.Share)
            }
            
            if self.navigationController?.modalPresentationStyle == .popover {
                actionMenu.append(Constants.Strings.Full_Screen)
            }
            
            if UIPrintInteractionController.isPrintingAvailable {
                actionMenu.append(Constants.Strings.Print)
            }
            
            popover.section.strings = actionMenu
            
            self.popover?["ACTION"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["ACTION"] = popover
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        playPauseButton = UIBarButtonItem(title: "Play", style: UIBarButtonItem.Style.plain, target: self, action: #selector(playPause))

        syncButton = UIBarButtonItem(title: "Sync", style: UIBarButtonItem.Style.plain, target: self, action: #selector(tracking))
        syncButton.isEnabled = wordRangeTiming != nil
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        cancelButton = UIBarButtonItem(title: Constants.Strings.Cancel, style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        
        if (Globals.shared.mediaPlayer.mediaItem != transcript?.mediaItem) || (transcript?.mediaItem?.playing != transcript?.purpose) {
            track = false
        }
        
        if !search {
            searchBar.removeFromSuperview()
            textViewToTop.constant = 14
        } else {
            // iOS 11 changed the height of search bars by 12 points!
            if #available(iOS 11.0, *) {
                textViewToTop.constant += 12
            } else {
                // Fallback on earlier versions
            }
        }
        
        navigationItem.leftBarButtonItem = cancelButton

        var barButtonItems = [UIBarButtonItem]()
        
        if track {
            barButtonItems.append(spaceButton)
            barButtonItems.append(syncButton)

            activityIndicator = UIActivityIndicatorView()
            activityIndicator.style = .gray
            activityIndicator.hidesWhenStopped = true
            
            activityBarButton = UIBarButtonItem(customView: activityIndicator)
            activityBarButton.isEnabled = true
            
            barButtonItems.append(activityBarButton)
            
            if wordRangeTiming == nil {
                activityIndicator.startAnimating()
            }

            barButtonItems.append(spaceButton)
            barButtonItems.append(playPauseButton)
        }

        saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        saveButton.tintColor = UIColor.red
        
        assistButton = UIBarButtonItem(title: "Assist", style: UIBarButtonItem.Style.plain, target: self, action: #selector(autoEdit))
        dismissButton = UIBarButtonItem(title: "Dismiss", style: UIBarButtonItem.Style.plain, target: self, action: #selector(dismissKeyboard))

        if assist {
            barButtonItems.append(spaceButton)
            barButtonItems.append(assistButton)
        }
        
        if !readOnly {
            barButtonItems.append(spaceButton)
            barButtonItems.append(saveButton)
            barButtonItems.append(spaceButton)
        } else {
            
        }

        toolbarItems = barButtonItems.count > 0 ? barButtonItems : nil
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
        
        if navigationItem.rightBarButtonItem == nil {
            navigationItem.rightBarButtonItem = actionButton
        } else {
            navigationItem.rightBarButtonItems?.append(actionButton)
        }
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .formSheet:
                fallthrough
            case .overCurrentContext:
                fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItem.Style.plain, target: self, action: #selector(showFullScreen))
                fullScreenButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
                
                if Globals.shared.splitViewController?.isCollapsed == false {
                    if navigationItem.rightBarButtonItems != nil {
                        navigationItem.rightBarButtonItems?.append(fullScreenButton)
                    } else {
                        navigationItem.rightBarButtonItem = fullScreenButton
                    }
                }

            case .fullScreen:
                fallthrough
            case .overFullScreen:
                break
                
            default:
                break
            }
        }

        navigationController?.toolbar.isTranslucent = false
    }
    
    func checkSync()
    {
        guard let transcript = self.transcript else {
            return
        }
        
        guard let wordRangeTiming = self.wordRangeTiming?.cache else {
            return
        }
        
        if  let transcriptString = transcript.transcript?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            let transcriptFromWordsString = transcript.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            
            if transcriptString != transcriptFromWordsString {
                print(prettyFirstDifferenceBetweenStrings(transcriptString as NSString, transcriptFromWordsString as NSString))
            }
            
            if  (Globals.shared.mediaPlayer.mediaItem == transcript.mediaItem),
                (transcript.mediaItem?.playing == transcript.purpose) { // , (transcriptString.lowercased() != transcriptFromWordsString.lowercased())
                if wordRangeTiming.filter({ (dict:[String:Any]) -> Bool in
                    return dict["range"] == nil
                }).count > 0 {
                    if let text = transcript.mediaItem?.text {
                        Alerts.shared.alert(title: "Transcript Sync Warning",message: "The transcript for\n\n\(text) (\(transcript.transcriptPurpose))\n\ndiffers from the individually recognized words.  As a result the sync will not be exact.  Please align the transcript for an exact sync.")
                    }
                }
            }
        }
    }
    
    @objc func stopped()
    {
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        isTracking = false

        updateBarButtons()
    }
    
    @objc func playing()
    {
        updateBarButtons()
    }
    
    @objc func paused()
    {
        updateBarButtons()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(stopped), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STOPPED), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = toolbarItems == nil

        addNotifications()
        
        searchBar.text = searchText
        searchBar.isUserInteractionEnabled = searchInteractive

        if let changedText = changedText {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.body)
        }
        
        if track {
            wordRangeTiming?.fill()
        }
        
        updateBarButtons()
    }
    
    // This has to be made interruptable.
    func addParagraphBreaks(automatic:Bool = false, interactive:Bool, makeVisible:Bool, showGapTimes:Bool, gapThreshold:Double? = nil, tooClose:Int? = nil, words:[[String:Any]]?, text:String?, completion:((String?)->(Void))?)
    {
        guard var words = words else {
            return
        }
        
        guard words.count > 0 else {
            if !automatic {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                    // This is where the text can be updated.
                    completion?(text)
                }))
                
                Alerts.shared.alert(category:nil,title:"Assisted Editing Complete",message:nil,attributedText: nil, actions: actions)
            }
            return
        }
        
        guard let text = text else {
            return
        }
        
        let first = words.removeFirst()
        
        guard let range = first["range"] as? Range<String.Index> else {
            return
        }
        
        let gap = first["gap"] as? Double
        
        var gapString = "\n\n"
        
        if showGapTimes, let gap = gap {
            gapString = "<\(gap)>" + gapString
        }

        let beforeFull = String(text[..<range.lowerBound])
        let stringFull = String(text[range])
        let afterFull = String(text[range.upperBound...])
        
        //////////////////////////////////////////////////////////////////////////////
        // If words.first["range"] (either lowerBound or upperBound) is "too close"
        // (whatever that is defined to be) to a paragraph break then we should skip
        // and move on to the next word.
        //////////////////////////////////////////////////////////////////////////////
        
        if let tooClose = tooClose {
            var lowerRange : Range<String.Index>?
            var upperRange : Range<String.Index>?
            
            var rng : Range<String.Index>?
            
            var searchRange : Range<String.Index>!
            
            searchRange = Range(uncheckedBounds: (lower: text.startIndex, upper: range.lowerBound))
            
            rng = text.range(of: "\n\n", options: .caseInsensitive, range:searchRange, locale: nil)
            
            // But even if there is a match we have to find the LAST match
            if rng != nil {
                repeat {
                    lowerRange = rng
                    searchRange = Range(uncheckedBounds: (lower: rng!.upperBound, upper: range.lowerBound))
                    rng = text.range(of: "\n\n", options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
                } while rng != nil
            } else {
                // NONE FOUND BEFORE
            }
            
            let block = {
                if !automatic {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                        self.updateBarButtons()
                    }))
                    
                    Alerts.shared.alert(category:nil,title:"Assisted Editing Complete",message:nil,attributedText: nil, actions: actions)
                }
            }
            
            // Too close to the previous?
            if let lowerRange = lowerRange {
                // encodedOffset
                if (lowerRange.upperBound.utf16Offset(in: text) + tooClose) > range.lowerBound.utf16Offset(in: text) {
                    if !interactive, gap < gapThreshold {
                        block()
                        return //even though we use this code 4 times, if we put it in a block we don't get this return!
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    editingQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }

                    return
                }
            } else {
                // There is no previous.
                
                // Too close to the start?
                if (text.startIndex.utf16Offset(in: text) + tooClose) > range.lowerBound.utf16Offset(in: text) {
                    if !interactive, gap < gapThreshold {
                        block()
                        return //even though we use this code 4 times, if we put it in a block we don't get this return!
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    editingQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    
                    return
                }
            }
            
            searchRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
            
            upperRange = text.range(of: "\n\n", options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
            
            // Too close to the next?
            if let upperRange = upperRange {
                if (range.upperBound.utf16Offset(in: text) + tooClose) > upperRange.lowerBound.utf16Offset(in: text) {
                    if !interactive, gap < gapThreshold {
                        block()
                        return //even though we use this code 4 times, if we put it in a block we don't get this return!
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    editingQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    
                    return
                }
            } else {
                // There is no next.
                
                // Too close to end?
                if (range.lowerBound.utf16Offset(in: text) + tooClose) > text.endIndex.utf16Offset(in: text) {
                    if !interactive, gap < gapThreshold {
                        block()
                        return //even though we use this code 4 times, if we put it in a block we don't get this return!
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    editingQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    
                    return
                }
            }
        }

        let fullAttributedString = NSMutableAttributedString()
        
        fullAttributedString.append(NSAttributedString(string: beforeFull,attributes: Constants.Fonts.Attributes.body))
        fullAttributedString.append(NSAttributedString(string: stringFull,attributes: Constants.Fonts.Attributes.highlighted))
        fullAttributedString.append(NSAttributedString(string: afterFull, attributes: Constants.Fonts.Attributes.body))
        
        if interactive {
            Thread.onMain {
                self.textView.attributedText = fullAttributedString
                self.textView.scrollRangeToVisible(range)
            }
            
            let before = "..." + String(text[..<range.lowerBound]).dropFirst(max(String(text[..<range.lowerBound]).count - 10,0))
            let string = String(text[range])
            let after = String(String(text[range.upperBound...]).dropLast(max(String(text[range.upperBound...]).count - 10,0))) + "..."
            
            let beforeAttr = NSMutableAttributedString(string: before, attributes: Constants.Fonts.Attributes.body)
            let stringAttr = NSMutableAttributedString(string: string, attributes: Constants.Fonts.Attributes.highlighted)
            let afterAttr = NSMutableAttributedString(string: after, attributes: Constants.Fonts.Attributes.body)
            
            let snippet = NSMutableAttributedString()
            
            snippet.append(beforeAttr)
            snippet.append(stringAttr)
            snippet.append(afterAttr)
            
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Show", style: .default, handler: {
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                    let textView = navigationController.viewControllers[0] as? TextViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext

                    textView.readOnly = true
                    
                    textView.text = fullAttributedString.string

                    textView.onDone = { (string:String) in
                        words.insert(first, at:0)
                        self.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    
                    Thread.onMain {
                        textView.navigationItem.title = self.navigationItem.title
                        
                        self.present(navigationController, animated: true, completion: {
                            textView.textView.attributedText = fullAttributedString
                            textView.textView.scrollRangeToVisible(range)
                        })
                    }
                }
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                var newText = text
                
                newText.insert(contentsOf:gapString, at: range.lowerBound)
                
                for i in 0..<words.count {
                    if let wordRange = words[i]["range"] as? Range<String.Index> {
                        if wordRange.lowerBound > range.lowerBound {
                            var lower : String.Index?
                            var upper : String.Index?
                            
                            lower = String.Index(utf16Offset: wordRange.lowerBound.utf16Offset(in: text) + gapString.endIndex.utf16Offset(in: gapString), in: newText)
                            
                            upper = String.Index(utf16Offset: wordRange.upperBound.utf16Offset(in: text) + gapString.endIndex.utf16Offset(in: gapString), in: newText)
                            
                            if let lower = lower, let upper = upper {
                                let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                                words[i]["range"] = newRange
                            }
                        }
                    }
                }
                
                // Calling completion when we change something makes sense?
                // To update the text and the changedText
                completion?(newText)
                
                self.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:newText, completion:completion)
            }))
            
            actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: {
                self.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold: gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                // Why is completion called when we cancel?
                // To update the text.
                completion?(text)
            }))
            
            let position = text.distance(from: text.startIndex, to: range.lowerBound)
            
            let distance = text.distance(from: text.startIndex, to: text.endIndex)
            
            Alerts.shared.alert(category:nil,title:"Insert paragraph break before the highlighted text?",message:"Gap: \(gap ?? 0) seconds\nat position \(position) of \(distance).",attributedText:snippet,actions:actions)
        } else {
            if let gapThreshold = gapThreshold, gap < gapThreshold {
                if !automatic {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                        self.updateBarButtons()
                    }))
                    
                    Alerts.shared.alert(category:nil,title:"Assisted Editing Complete",message:nil,attributedText: nil, actions: actions)
                }
                return
            }
            
            if makeVisible {
                // Should this be optional?  It makes it possible to see the changes happening.
                Thread.onMain { () -> (Void) in
                    self.textView.attributedText = fullAttributedString
                    self.textView.scrollRangeToVisible(range)
                }
                ////////////////////////////////////////////////////////////////////////////////
                Thread.sleep(forTimeInterval: 1.0)
                ////////////////////////////////////////////////////////////////////////////////
            }
            
            var newText = text
            newText.insert(contentsOf:gapString, at: range.lowerBound)

            var lower : String.Index?
            var upper : String.Index?
            var newRange : Range<String.Index>?
            
            if range.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                lower = newText.index(range.lowerBound, offsetBy: gapString.count)
            }
            
            if range.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                upper = newText.index(range.upperBound, offsetBy: gapString.count)
            }
            
            if let lower = lower, let upper = upper {
                newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
            }

            for i in 0..<words.count {
                if let wordRange = words[i]["range"] as? Range<String.Index> {
                    if wordRange.lowerBound > range.lowerBound {
                        var lower : String.Index?
                        var upper : String.Index?
                        
                        if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                            lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                        }
                        
                        if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                            upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                        }
                        
                        if let lower = lower, let upper = upper {
                            let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                            words[i]["range"] = newRange
                        }
                    }
                }
            }
            
            editingQueue.addOperation { [weak self] in
                // Why is completion called here?
                // So the text is updated.
                completion?(newText)
//                Thread.onMain {
//                }
                
                if makeVisible {
                    ////////////////////////////////////////////////////////////////////////////////
                    Thread.onMain { () -> (Void) in
                        if let newRange = newRange {
                            self?.textView.scrollRangeToVisible(newRange)
                        }
                    }
                    Thread.sleep(forTimeInterval: 1.0)
                    ////////////////////////////////////////////////////////////////////////////////
                }
                self?.addParagraphBreaks(interactive:interactive, makeVisible:makeVisible, showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:newText, completion:completion)
            }
        }
    }
    
    func changeText(interactive:Bool, makeVisible:Bool, text:String?, startingRange:Range<String.Index>?, changes:[(String,String)]?, completion:((String)->(Void))?) // [String:[String:String]]
    {
        guard var text = text else {
            return
        }
        
        guard var changes = changes, let change = changes.first else {
            if !automatic {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                    self.updateBarButtons()
                }))
                
                Alerts.shared.alert(category:nil,title:"Assisted Editing Complete",message:nil,attributedText: nil, actions: actions)
            } else {
                editingQueue.addOperation {
                    Thread.onMain {
                        self.dismiss(animated: true, completion: nil)
                    }
                    self.onDone?(self.textView.attributedText.string)
                    self.automaticCompletion?()
                }
            }
            return
        }
        
        let oldText = change.0
        let newText = change.1
        
        var range : Range<String.Index>?
        
        if oldText == oldText.lowercased(), oldText.lowercased() != newText.lowercased() {
            if startingRange == nil {
                range = text.lowercased().range(of: oldText)
            } else {
                range = text.lowercased().range(of: oldText, options: [], range:  startingRange, locale: nil)
            }
        } else {
            if startingRange == nil {
                range = text.range(of: oldText)
            } else {
                range = text.range(of: oldText, options: [], range:  startingRange, locale: nil)
            }
        }
        
        if let range = range { // , let value = masterChanges[masterKey]?[key]
            let fullAttributedString = NSMutableAttributedString()
            
            let beforeFull = String(text[..<range.lowerBound])
            let stringFull = String(text[range])
            let afterFull = String(text[range.upperBound...])
            
            fullAttributedString.append(NSAttributedString(string: beforeFull,attributes: Constants.Fonts.Attributes.body))
            fullAttributedString.append(NSAttributedString(string: stringFull,attributes: Constants.Fonts.Attributes.highlighted))
            fullAttributedString.append(NSAttributedString(string: afterFull, attributes: Constants.Fonts.Attributes.body))
            
            let attributedString = NSMutableAttributedString()
            
            let before = "..." + String(text[..<range.lowerBound]).dropFirst(max(String(text[..<range.lowerBound]).count - 10,0))
            let string = String(text[range])
            let after = String(String(text[range.upperBound...]).dropLast(max(String(text[range.upperBound...]).count - 10,0))) + "..."
            
            attributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.body))
            attributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
            attributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.body))
            
            let prior = String(text[..<range.lowerBound]).last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let following = String(text[range.upperBound...]).first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // what about other surrounding characters besides newlines and whitespaces, and periods if following?
            // what about other token delimiters?
            if (prior?.isEmpty ?? true) && ((following?.isEmpty ?? true) || (following == ".")) {
                if interactive {
                    let fullAttributedString = NSMutableAttributedString()

                    let before = String(text[..<range.lowerBound])
                    let string = String(text[range])
                    let after = String(text[range.upperBound...])

                    fullAttributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.body))
                    fullAttributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
                    fullAttributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.body))

                    Thread.onMain {
                        self.textView.attributedText = fullAttributedString
                        self.textView.scrollRangeToVisible(range)
                    }
                    
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: "Show", style: .default, handler: {
                        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                            let textView = navigationController.viewControllers[0] as? TextViewController {
                            navigationController.modalPresentationStyle = .overCurrentContext
                            
                            textView.readOnly = true
                            
                            textView.text = fullAttributedString.string
                            
                            textView.onDone = { (string:String) in
                                let startingRange = Range(uncheckedBounds: (lower: range.lowerBound, upper: text.endIndex))
                                self.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:startingRange, changes:changes, completion:completion)
                            }
                            
                            Thread.onMain {
                                textView.navigationItem.title = self.navigationItem.title
                                
                                self.present(navigationController, animated: true, completion: {
                                    textView.textView.attributedText = fullAttributedString
                                    textView.textView.scrollRangeToVisible(range)
                                })
                            }
                        }
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                        let vc = self
                        
                        text.replaceSubrange(range, with: newText)
                        
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.body)
                        
                        completion?(text)
                        
                        let before = String(text[..<range.lowerBound])
                        
                        if let completedRange = text.range(of: before + newText) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            
                            // THIS ALLOWS THE TEXT TO CHANGE
                            // USE PROCESS TO SHOW THE USER A SPINNER UNTIL THE FIRST CHANGE IS FOUND!
                            
                            // test:(()->(Bool))?
                            vc.process(work: { [weak self] () -> (Any?) in
                                self?.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:startingRange, changes:changes, completion:completion)
                                
                                self?.editingQueue.waitUntilAllOperationsAreFinished()
                                
                                return nil
                            }) { [weak self] (data:Any?) in
                                
                            }
                        } else {
                            // ERROR
                        }
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: {
                        let vc = self
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.body)
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        
                        // USE PROCESS TO SHOW THE USER A SPINNER UNTIL THE FIRST CHANGE IS FOUND!

                        // test:(()->(Bool))?
                        vc.process(work: { [weak self] () -> (Any?) in
                            self?.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:startingRange, changes:changes, completion:completion)
                            
                            self?.editingQueue.waitUntilAllOperationsAreFinished()
                            
                            return nil
                        }) { [weak self] (data:Any?) in
                            
                        }
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.body)
                    }))
                    
                    Alerts.shared.alert(category:nil,title:"Change \"\(string)\" to \"\(newText)\"?",message:nil,attributedText:attributedString,actions:actions)
                } else {
                    editingQueue.addOperation { [weak self] in
                        if makeVisible {
                            // Should this be optional?  It makes it possible to see the changes happening.
                            Thread.onMain { () -> (Void) in
                                self?.textView.attributedText = fullAttributedString
                                self?.textView.scrollRangeToVisible(range)
                            }
                            ////////////////////////////////////////////////////////////////////////////////
                            Thread.sleep(forTimeInterval: 1.0)
                            ////////////////////////////////////////////////////////////////////////////////
                        }

                        text.replaceSubrange(range, with: newText)

                        // This makes the change visible
                        completion?(text)
//                        Thread.onMain {
//                        }

                        if makeVisible {
                            ////////////////////////////////////////////////////////////////////////////////
                            Thread.sleep(forTimeInterval: 1.0)
                            ////////////////////////////////////////////////////////////////////////////////
                        }

                        let before = String(text[..<range.lowerBound])
                        
                        if let completedRange = text.range(of: before + newText) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            self?.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:startingRange, changes:changes, completion:completion)
                        } else {
                            // ERROR
                        }
                    }
                }
            } else {
                let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                editingQueue.addOperation { [weak self] in
                    self?.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:startingRange, changes:changes, completion:completion)
                }
            }
        } else {
            changes.removeFirst()
            editingQueue.addOperation { [weak self] in
                self?.changeText(interactive:interactive, makeVisible:makeVisible, text:text, startingRange:nil, changes:changes, completion:completion)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if readOnly, notifyReadOnly {
            Alerts.shared.alert(title: "Read Only", message: "While the text can be edited, it cannot be saved.")
        }

        if isTracking {
            // Why are these commented out?
            //            startTracking()
            //            removeAssist()
            oldRange = nil // Forces the range to be highlighted.
        } else {
            textView.scrollRangeToVisible(NSMakeRange(0, 0))
        }
        
        if automatic {
            let text = self.textView.attributedText.string
            
            // USING PROCESS BECAUSE WE ARE USING THE OPERATION QUEUE - MAYBE, depends on automaticInteractive
            
            // test:(()->(Bool))?
            self.process(work: { [weak self] () -> (Any?) in
                guard let changes = self?.transcript?.changes(interactive:self?.automaticInteractive == true, longFormat:false) else {
                    return nil
                }
                
                self?.changeText(interactive: self?.automaticInteractive == true, makeVisible:self?.automaticVisible == true, text: text, startingRange: nil, changes: changes, completion: { (string:String) -> (Void) in
                    self?.changedText = string
                    Thread.onMain {
                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
                    }
                })
                
                self?.editingQueue.waitUntilAllOperationsAreFinished()

                return nil
            }) { [weak self] (data:Any?) in

            }
        } else {

        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard (self.view.window == nil) else {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)

        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)

    }
}

