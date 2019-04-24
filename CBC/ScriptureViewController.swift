//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

extension ScriptureViewController : UIAdaptivePresentationControllerDelegate
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

extension ScriptureViewController : UIActivityItemSource
{
    func share()
    {
        guard let html = webViewController?.html.string else {
            return
        }
        
        let print = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = UIActivityViewController(activityItems:[self,html,print] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        // present the view controller
        Thread.onMainThread {
            self.present(activityViewController, animated: true, completion: nil)
        }
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
        
        guard let html = webViewController?.html.string else {
            return nil
        }
        
        if #available(iOS 11.0, *) {
            ScriptureViewController.cases.append(.markupAsPDF)
        }
        
        if ScriptureViewController.cases.contains(activityType) {
            return html
        }
        
        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return self.navigationItem.title ?? "" // mediaItem?.text ?? (transcript?.mediaItem?.text ?? ( ?? ""))
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

extension ScriptureViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate

    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
//        popover?.dismiss(animated: true, completion: nil)
        popover?["ACTION"]?.dismiss(animated: true, completion: { [weak self] in
            self?.popover?["ACTION"] = nil
        })

        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
            case Constants.Strings.Full_Screen:
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? WebViewController {
                    navigationController.modalPresentationStyle = .overFullScreen
                    navigationController.popoverPresentationController?.delegate = popover
                    
                    popover.navigationItem.title = self.navigationItem.title
                    
                    if let webViewController = self.webViewController {
                        popover.html.fontSize = webViewController.html.fontSize
                        popover.html.string = webViewController.html.string
                        popover.mediaItem = webViewController.mediaItem
                        popover.content = webViewController.content
                    }
                                        
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    present(navigationController, animated: true, completion: nil)
                }
                break
                
            case Constants.Strings.Print:
                if let string = webViewController?.html.string, string.contains(" href=") {
                    self.firstSecondCancel(title: "Remove Links?", message: nil, //"This can take some time.",
                        firstTitle: Constants.Strings.Yes,
                        firstAction: {
                            self.process(work: { [weak self] () -> (Any?) in
                                return self?.webViewController?.html.string?.stripLinks
                                }, completion: { [weak self] (data:Any?) in
                                    if let vc = self {
                                        vc.printHTML(htmlString: data as? String)
                                    }
                            })
                    }, firstStyle: .default,
                       secondTitle: Constants.Strings.No,
                       secondAction: {
                        self.printHTML(htmlString: self.webViewController?.html.string)
                    }, secondStyle: .default)
                } else {
                    self.printHTML(htmlString: self.webViewController?.html.string)
                }
                break
                
            case Constants.Strings.Lexical_Analysis:
                self.process(disableEnable: false, hideSubviews: false, work: { () -> (Any?) in
                    if #available(iOS 12.0, *) {
                        return self.scripture?.text(self.scripture?.reference)?.nlNameAndLexicalTypesMarkup(annotated:true)
                    } else {
                        // Fallback on earlier versions
                        return self.scripture?.text(self.scripture?.reference)?.nsNameAndLexicalTypesMarkup(annotated:true)
                    }
                }) { (data:Any?) in
                    if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? WebViewController {
                        popover.navigationItem.title = (self.scripture?.reference ?? "") +  " Lexical Analysis"
                        navigationController.isNavigationBarHidden = false
                        
                        navigationController.modalPresentationStyle = .overCurrentContext
                        navigationController.popoverPresentationController?.delegate = self
                        
                        popover.html.string = data as? String
                        popover.content = .html
                        
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
                break
                
            case Constants.Strings.Search:
                self.searchAlert(title: "Search", message: nil, searchText:webViewController?.searchText, searchAction:  { (alert:UIAlertController) -> (Void) in
                    self.webViewController?.searchText = alert.textFields?[0].text
                    
                    self.webViewController?.wkWebView?.isHidden = true
                    
                    self.webViewController?.activityIndicator.isHidden = false
                    self.webViewController?.activityIndicator.startAnimating()
                    
                    if let isEmpty = self.webViewController?.searchText?.isEmpty, isEmpty {
                        self.webViewController?.html.string = self.webViewController?.html.original?.stripHead.insertHead(fontSize: self.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                    } else {
                        if self.webViewController?.bodyHTML != nil { // , self.headerHTML != nil // Not necessary
                            self.webViewController?.html.string = self.webViewController?.bodyHTML?.markHTML(headerHTML: self.webViewController?.headerHTML, searchText:self.webViewController?.searchText, wholeWordsOnly: false, lemmas: false, index: true).0?.stripHead.insertHead(fontSize: self.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                        } else {
                            self.webViewController?.html.string = self.webViewController?.html.original?.markHTML(searchText:self.webViewController?.searchText, wholeWordsOnly: false, index: true).0?.stripHead.insertHead(fontSize: self.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                        }
                    }
                    
                    if let url = self.webViewController?.html.fileURL {
                        self.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }
                })
                break
                
            case Constants.Strings.Word_Picker:
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = self
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.delegate = webViewController
                    
//                    popover.actionTitle = Constants.Strings.Expanded_View
//                    popover.action = { (String) in
//                        self.process(work: { [weak self] () -> (Any?) in
//                            return popover.stringTree?.html
//                        }, completion: { [weak self] (data:Any?) in
//                            popover.presentHTMLModal(mediaItem: nil, style: .fullScreen, title: Constants.Strings.Expanded_View, htmlString: data as? String)
//                        })
//                    }

//                    popover.stringTree = StringTree()
                    
                    popover.navigationItem.title = navigationItem.title // Constants.Strings.Word_Picker
                    
                    popover.stringsFunction = {
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return self.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                            return word
                        }).sorted()
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
                    
                    if let mediaItem = mediaItem {
                        popover.cloudTitle = mediaItem.title
                        
                        popover.cloudString = self.webViewController?.bodyHTML?.html2String
                        
                        popover.cloudWordDictsFunction = { [weak self] in
                            let words:[[String:Any]]? = self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (key:String, value:Int) -> [String:Any] in
                                return ["word":key,"count":value,"selected":true]
                            })
                            
                            return words
                        }
                    }
                    
                    popover.cloudTitle =  (self.scripture?.reference ?? "") // navigationItem.title
                    
                    popover.cloudWordDictsFunction = { [weak self] in
                        let words = self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> [String:Any] in
                            return ["word":word,"count":count,"selected":true]
                        })
                        
                        return words
                    }
                    
                    popover.cloudFont = UIFont.preferredFont(forTextStyle:.body)
                    
                    present(navigationController, animated: true, completion:  nil)
                }
                break
                
            case Constants.Strings.Words:
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = self
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = navigationItem.title
                    
                    popover.delegate = self
                    popover.purpose = .selectingWord
                    
                    popover.segments = true
                    
                    popover.section.function = { (method:String?,strings:[String]?) in
                        return strings?.sort(method: method)
                    }
                    popover.section.method = Constants.Sort.Alphabetical
                    
                    popover.bottomBarButton = true
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak popover] in
                        guard let popover = popover else {
                            return
                        }
                        
                        let strings = popover.section.function?(Constants.Sort.Alphabetical,popover.section.strings)
                        
                        if popover.segmentedControl.selectedSegmentIndex == 0 {
                            popover.section.method = Constants.Sort.Alphabetical
                            
                            popover.section.showHeaders = false
                            popover.section.showIndex = true
                            
                            popover.section.indexStringsTransform = nil
                            popover.section.indexHeadersTransform = nil
                            popover.section.indexSort = nil
                            
                            popover.section.sorting = true
                            popover.section.strings = strings
                            popover.section.sorting = false
                            
                            popover.section.stringsAction?(strings, popover.section.sorting)

                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak popover] in
                        guard let popover = popover else {
                            return
                        }
                        
                        let strings = popover.section.function?(Constants.Sort.Frequency,popover.section.strings)
                        
                        if popover.segmentedControl.selectedSegmentIndex == 1 {
                            popover.section.method = Constants.Sort.Frequency
                            
                            popover.section.showHeaders = false
                            popover.section.showIndex = true
                            
                            popover.section.indexStringsTransform = { (string:String?) -> String? in
                                return string?.log
                            }
                            
                            popover.section.indexHeadersTransform = { (string:String?) -> String? in
                                return string
                            }
                            
                            popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                                guard let first = first else {
                                    return false
                                }
                                guard let second = second else {
                                    return true
                                }
                                return Int(first) > Int(second)
                            }
                            
                            popover.section.sorting = true
                            popover.section.strings = strings
                            popover.section.sorting = false
                            
                            popover.section.stringsAction?(strings, popover.section.sorting)
                            
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    popover.section.showIndex = true
                    
                    popover.search = true
                    
                    popover.stringsFunction = { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                            return "\(word) (\(count))"
                        }).sorted()
                    }
                    
                    self.popover?["WORD"] = popover
                    
                    popover.completion = { [weak self] in
                        self?.popover?["WORD"] = nil
                    }
                    
                    present(navigationController, animated: true, completion: nil)
                }
                break
                
            case Constants.Strings.Share:
                share()
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

//extension ScriptureViewController : PopoverPickerControllerDelegate
//{
//    // MARK: PopoverPickerControllerDelegate
//
//    func stringPicked(_ string: String?, purpose:PopoverPurpose?)
//    {
//        guard self.isViewLoaded else {
//            return
//        }
//
//        guard Thread.isMainThread else {
//            self.alert(title: "Not Main Thread", message: "ScriptureViewController:stringPicked", completion: nil)
//            return
//        }
//
//        guard let string = string else {
//            return
//        }
//
//        dismiss(animated: true, completion: nil)
//
//        self.navigationController?.popToRootViewController(animated: true) // Why are we doing this?
//
//        var searchText = string
//
//        if let range = searchText.range(of: " (") {
//            searchText = String(searchText[..<range.lowerBound])
//        }
//
//        self.webViewController?.wkWebView?.isHidden = true
//
//        self.webViewController?.activityIndicator.isHidden = false
//        self.webViewController?.activityIndicator.startAnimating()
//
//        if webViewController?.bodyHTML != nil { // , headerHTML != nil // Not necessary
//            webViewController?.html.string = webViewController?.bodyHTML?.markHTML(headerHTML: webViewController?.headerHTML, searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true).0
//        }
//
//        webViewController?.html.string = webViewController?.html.string?.stripHead.insertHead(fontSize: webViewController?.html.fontSize ?? Constants.FONT_SIZE)
//
//        if let url = self.webViewController?.html.fileURL {
//            webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
//        }
//    }
//}

//extension ScriptureViewController : UIPickerViewDataSource
//{
//    // MARK: UIPickerViewDataSource
//
//    func numberOfComponents(in pickerView: UIPickerView) -> Int
//    {
//        return includeVerses ? 4 : 3  // Compact width => 3, otherwise 5?  (beginning and ending verses)
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
//    {
//        var numberOfRows = 1
//
//        switch component {
//        case 0:
//            numberOfRows = 2 // N.T. or O.T.
//            break
//
//        case 1:
//            if scripture?.selected.testament != nil, let books = scripture?.picker.books {
//                numberOfRows = books.count
//            } else {
//                numberOfRows = 0 // number of books in testament
//            }
//            break
//
//        case 2:
//            guard scripture?.selected.testament != nil else {
//                numberOfRows = 0
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                numberOfRows = 0
//                break
//            }
//
//            if let chapters = scripture?.picker.chapters {
//                numberOfRows = chapters.count
//            }
//            break
//
//        case 3:
//            guard includeVerses else {
//                numberOfRows = 0
//                break
//            }
//
//            guard scripture?.selected.testament != nil else {
//                numberOfRows = 0
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                numberOfRows = 0
//                break
//            }
//
//            guard scripture?.selected.chapter > 0 else {
//                numberOfRows = 0
//                break
//            }
//
//            if let verses = scripture?.picker.verses {
//                numberOfRows = verses.count
//            }
//            break
//
//        default:
//            break
//        }
//
//        return numberOfRows
//    }
//
//    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
//    {
//        let label = (view as? UILabel) ?? UILabel()
//
//        if let title = title(forRow: row, forComponent: component) {
//            label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.normal)
//        }
//
//        return label
//    }
//
//    func title(forRow row:Int, forComponent component:Int) -> String?
//    {
//        switch component {
//        case 0:
//            if row == 0 {
//                return Constants.OT
//            }
//            if row == 1 {
//                return Constants.NT
//            }
//            break
//
//        case 1:
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            if let book = scripture?.picker.books?[row] {
//                return book
//            }
//            break
//
//        case 2:
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                break
//            }
//
//            if let chapters = scripture?.picker.chapters {
//                return "\(chapters[row])"
//            }
//            break
//
//        case 3:
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                break
//            }
//
////            if scripture?.selected.chapter > 0 {
////                return "1"
////            }
//
//            if let verses = scripture?.picker.verses {
//                return "\(verses[row])"
//            }
//            break
//
//        default:
//            break
//        }
//
//        return Constants.EMPTY_STRING
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
//    {
//        return title(forRow: row,forComponent: component)
//    }
//}

//extension ScriptureViewController : UIPickerViewDelegate
//{
//    // MARK: UIPickerViewDelegate
//
//    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
//    {
//        // These should be dynamic
//        switch component {
//        case 0:
//            return 50
//
//        case 1:
//            return 175
//
//        case 2:
//            return 35
//
//        case 3:
//            return 35
//
//        default:
//            return 0
//        }
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
//    {
//        switch component {
//        case 0: // Testament
//            switch row {
//            case 0:
//                scripture?.selected.testament = Constants.OT
//                break
//
//            case 1:
//                scripture?.selected.testament = Constants.NT
//                break
//
//            default:
//                break
//            }
//
//            if let testament = scripture?.selected.testament {
//                switch testament {
//                case Constants.OT:
//                    scripture?.picker.books = Constants.OLD_TESTAMENT_BOOKS
//                    break
//
//                case Constants.NT:
//                    scripture?.picker.books = Constants.NEW_TESTAMENT_BOOKS
//                    break
//
//                default:
//                    break
//                }
//            }
//
//            scripture?.selected.book = scripture?.picker.books?[0]
//
//            updatePicker()
//
//            if let chapter = scripture?.picker.chapters?[0] {
//                scripture?.selected.chapter = chapter
//            }
//
//            pickerView.reloadAllComponents()
//
//            if pickerView.numberOfComponents > 1 {
//                pickerView.selectRow(0, inComponent: 1, animated: true)
//            }
//
//            if pickerView.numberOfComponents > 2 {
//                pickerView.selectRow(0, inComponent: 2, animated: true)
//            }
//
//            updateReferenceLabel()
//            break
//
//        case 1: // Book
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            scripture?.selected.book = scripture?.picker.books?[row]
//
//            updatePicker()
//
//            if let chapter = scripture?.picker.chapters?[0] {
//                scripture?.selected.chapter = chapter
//            }
//
//            pickerView.reloadAllComponents()
//
//            if pickerView.numberOfComponents > 2 {
//                pickerView.selectRow(0, inComponent: 2, animated: true)
//            }
//
//            updateReferenceLabel()
//            break
//
//        case 2: // Chapter
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                break
//            }
//
//            if let chapter = scripture?.picker.chapters?[row] {
//                scripture?.selected.chapter = chapter
//            }
//
//            updatePicker()
//
//            if let verse = scripture?.picker.verses?[0] {
//                scripture?.selected.verse = verse
//            }
//
//            pickerView.reloadAllComponents()
//
//            if pickerView.numberOfComponents > 3 {
//                pickerView.selectRow(0, inComponent: 3, animated: true)
//            }
//
//            updateReferenceLabel()
//            break
//
//        case 3: // Verse
//            guard scripture?.selected.testament != nil else {
//                break
//            }
//
//            guard scripture?.selected.book != nil else {
//                break
//            }
//
//            guard scripture?.selected.chapter > 0 else {
//                break
//            }
//
//            if let verse = scripture?.picker.verses?[row] {
//                scripture?.selected.verse = verse
//            }
//
////            pickerView.reloadAllComponents()
//
//            updateReferenceLabel()
//            break
//
//        default:
//            break
//        }
//
//        showScripture()
//    }
//}

extension ScriptureViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ScriptureViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class ScriptureViewController : UIViewController
{
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

    var includeVerses = false
    
    var minusButton:UIBarButtonItem?
    var plusButton:UIBarButtonItem?
    var actionButton:UIBarButtonItem?
    
    var webViewController:WebViewController?
    var scripturePickerViewController:ScripturePickerViewController?
    
    var mediaItem : MediaItem?
    
    var scripture:Scripture?
    {
        didSet {
//            webViewController?.bodyHTML = scripture?.text(scripture?.reference)
            scripturePickerViewController?.scripture = scripture
        }
    }
    
    @IBOutlet weak var directionLabel: UILabel!
    
//    @IBOutlet weak var scripturePicker: UIPickerView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        
        if let visibleViewController = (destination as? UINavigationController)?.visibleViewController {
            destination = visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case "Show Web View":
                if let wvc = destination as? WebViewController {
                    webViewController = wvc
                    
                    // Just not ready.
                    //                    webViewController?.search = true
                    
                    webViewController?.html.string = "" // Why?
                    if let fontSize = fontSize {
                        webViewController?.html.fontSize = fontSize
                    }
                    webViewController?.content = .html
                }
                break
                
            case "Show Scripture Picker":
                if let spvc = destination as? ScripturePickerViewController {
                    scripturePickerViewController = spvc
                    scripturePickerViewController?.scripture = scripture
//                    scripturePickerViewController?.includeVerses = true
                    scripturePickerViewController?.show = { [weak self] in
                        self?.showScripture()
                        self?.setupBarButtons()
                        self?.updateReferenceLabel()
                    }
                }
                break
                
            default:
                break
            }
        }
    }
    
//    func actionMenu() -> [String]?
//    {
//        return webViewController?.actionMenu()
//
////        var actionMenu = [String]()
////
////        actionMenu.append("Lexical Analysis")
////
////        return actionMenu.count > 0 ? actionMenu : nil
//    }
    
    @objc func actions()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:actions", completion: nil)
            return
        }

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

            webViewController?.bodyHTML = scripture?.text(scripture?.reference)
            popover.section.strings = webViewController?.actionMenu()

            self.popover?["ACTION"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["ACTION"] = nil
            }
            
            self.present(navigationController, animated: true, completion:  nil)
        }
    }
    
    func updateReferenceLabel()
    {
        print(scripture?.reference)
    }

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
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        enableToolBarButtons()
    }
    
    func clearView()
    {
        Thread.onMainThread {
            self.navigationItem.title = nil
            self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            for view in self.view.subviews {
                view.isHidden = true
            }
        }
    }
    
    @objc func setPreferredContentSize()
    {
        guard navigationController?.modalPresentationStyle == .popover else {
            return
        }
        
        if let widthView = presentingViewController?.view ?? view, let wkWebView = webViewController?.wkWebView {
            if let height = scripturePickerViewController?.scripturePicker.frame.height {
                preferredContentSize = CGSize(  width:  widthView.frame.width,
                                                height: wkWebView.scrollView.contentSize.height + height + 60)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        if (self.view.window == nil) {
            return
        }

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            Thread.onMainThread {
                self.setPreferredContentSize()
            }
        }
    }
    
    func showScripture()
    {
        guard let reference = self.scripture?.selected.reference else {
            return
        }
        
        // This is MANDATORY or loading the scripture won't work.
        // The problem is this means the scripture object for the selected mediaItem
        // is changed and the scripture reference may no longer match what is
        // shown with the title.
        scripture?.reference = reference
        
        if self.scripture?.html?[reference] != nil {
            if let string = self.scripture?.html?[reference] {
                self.webViewController?.html.string = string.stripHead.insertHead(fontSize:webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                
                if let url = self.webViewController?.html.fileURL {
                    self.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }

                self.webViewController?.view.isHidden = false
            }
        } else {
            self.process(work: { [weak self] () -> (Any?) in
                self?.scripture?.load() // reference
                return self?.scripture?.html?[reference]
            }) { [weak self] (data:Any?) in
                if let string = data as? String {
//                        self?.webViewController?.html.string = string

                    self?.webViewController?.html.string = string.stripHead.insertHead(fontSize:self?.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                    
                    if let url = self?.webViewController?.html.fileURL {
                        self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }

//                    if let string =  { //
//                    } else {
//                        if let url = self?.webViewController?.html.fileURL {
//                            self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
//                        }
//                    }
                } else {
                    var bodyString = "<!DOCTYPE html><html><body>"
                    
                    bodyString = bodyString + "Network error.  Scripture text unavailable."
                    
                    bodyString = bodyString + "</body></html>"

                    self?.webViewController?.html.string = bodyString.insertHead(fontSize:self?.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                    
                    if let url = self?.webViewController?.html.fileURL {
                        self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }

//                    if let string = bodyString.insertHead(fontSize:self?.webViewController?.html.fontSize ?? Constants.FONT_SIZE) { //
//                    }
                }

                self?.webViewController?.view.isHidden = false
            }
        }
    }
    
    @objc func decreaseFontSize()
    {
        webViewController?.decreaseFontSize()
        
        if let fontSize = webViewController?.html.fontSize {
            UserDefaults.standard.set(fontSize, forKey: "SCRIPTURE VIEW FONT SIZE")
        } else {
            UserDefaults.standard.removeObject(forKey: "SCRIPTURE VIEW FONT SIZE")
        }
    }
    
    @objc func increaseFontSize()
    {
        webViewController?.increaseFontSize()
        
        if let fontSize = webViewController?.html.fontSize {
            UserDefaults.standard.set(fontSize, forKey: "SCRIPTURE VIEW FONT SIZE")
        } else {
            UserDefaults.standard.removeObject(forKey: "SCRIPTURE VIEW FONT SIZE")
        }
    }

    var fontSize : Int?
    {
        get {
            if UserDefaults.standard.object(forKey: "SCRIPTURE VIEW FONT SIZE") != nil {
                return UserDefaults.standard.integer(forKey: "SCRIPTURE VIEW FONT SIZE")
            } else {
                return nil
            }
        }
    }
    
    @objc func done()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    @objc func showFullScreen()
    {
        guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SCRIPTURE_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? ScriptureViewController else {
            return
        }

        dismiss(animated: false, completion: nil)
        
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.popoverPresentationController?.delegate = popover
        
        popover.navigationItem.title = self.scripture?.description // navigationItem.title

        popover.scripture = scripture
        
        popover.navigationController?.isNavigationBarHidden = false
        
        Globals.shared.splitViewController?.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func resetScripture()
    {
        scripture?.selected.clear()
        scripture?.reference = mediaItem?.scriptureReference
        setupPicker()
        navigationController?.isToolbarHidden = true

//        scripturePickerViewController?.updatePicker()
//        updatePicker()
    }
    
    fileprivate func setupBarButtons()
    {
        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(increaseFontSize))
        plusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(decreaseFontSize))
        minusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        let fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItem.Style.plain, target: self, action: #selector(showFullScreen))
        fullScreenButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
        
        if let minusButton = minusButton, let plusButton = plusButton, let actionButton = actionButton, let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .formSheet:
                navigationItem.setRightBarButtonItems([actionButton,fullScreenButton,minusButton,plusButton], animated: true)
                
            case .overCurrentContext:
                if Globals.shared.splitViewController?.isCollapsed == false {
                    navigationItem.setRightBarButtonItems([actionButton,fullScreenButton,minusButton,plusButton], animated: true)
                } else {
                    navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton], animated: true)
                }
                
            case .fullScreen:
                fallthrough
                
            case .overFullScreen:
                navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton], animated: true)

            default:
                break
            }
        }

        navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done)), animated: true)

        guard let scriptureReference = mediaItem?.scriptureReference else {
            navigationController?.isToolbarHidden = true
            return
        }
        
        let mediaItemScripture = Scripture(reference: scriptureReference)
        
        if let book = mediaItemScripture.booksChaptersVerses?.books?.sorted(by: { self.scripture?.reference?.range(of: $0)?.lowerBound < self.scripture?.reference?.range(of: $1)?.lowerBound }).first {
            let testament = book.testament.translateTestament
            
            let chapter = mediaItemScripture.booksChaptersVerses?[book]?.keys.sorted()[0]
            
            if (scripture?.selected.testament != testament) ||  (scripture?.selected.book != book) || (scripture?.selected.chapter != chapter) {
                let resetButton = UIBarButtonItem(title: "Reset", style: UIBarButtonItem.Style.plain, target: self, action: #selector(resetScripture))
                
                let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                
                var barButtons = [UIBarButtonItem]()
                
                barButtons.append(spaceButton)
                barButtons.append(resetButton)
                barButtons.append(spaceButton)
                
                navigationController?.toolbar.isTranslucent = false
                
                setToolbarItems(barButtons, animated: true)
                
                navigationController?.isToolbarHidden = false
            }
        }
    }
    
//    var activityViewController:UIActivityViewController?

//    var orientation : UIDeviceOrientation?
    
    @objc func deviceOrientationDidChange()
    {
//        guard let orientation = orientation else {
//            return
//        }
//
//        func action()
//        {
//            popover?["ACTION"]?.dismiss(animated: false, completion: { [weak self] in
//                self?.popover?["ACTION"] = nil
//            })
//            activityViewController?.dismiss(animated: false, completion: nil)
//        }
//
//        // Dismiss any popover
//        switch orientation {
//        case .faceUp:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .faceDown:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .landscapeLeft:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .landscapeRight:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                break
//
//            case .landscapeRight:
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .portrait:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .portraitUpsideDown:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .unknown:
//            break
//
//        @unknown default:
//            break
//        }
//
//        switch UIDevice.current.orientation {
//        case .faceUp:
//            break
//
//        case .faceDown:
//            break
//
//        case .landscapeLeft:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .landscapeRight:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .portrait:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .portraitUpsideDown:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .unknown:
//            break
//
//        @unknown default:
//            break
//        }
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
    }
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "SVC" // Asumes there is only ever one at a time globally.
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    func setupPicker()
    {
        if scripture?.selected.reference == nil, let reference = scripture?.reference, let books = reference.books, books.count > 0 {
            webViewController?.view.isHidden = true
            
            //            DispatchQueue.global(qos: .background).async { [weak self] in
            operationQueue.addOperation { [weak self] in
                self?.scripture?.reference = reference // Why?
                self?.scripture?.load()
                
                if let books = self?.scripture?.booksChaptersVerses?.books?.sorted(by: { self?.scripture?.reference?.range(of: $0)?.lowerBound < self?.scripture?.reference?.range(of: $1)?.lowerBound }) {
                    let book = books[0]
                    
                    self?.scripture?.selected.testament = book.testament.translateTestament
                    self?.scripture?.selected.book = book
                    
                    if let chapters = self?.scripture?.booksChaptersVerses?[book]?.keys.sorted() {
                        self?.scripture?.selected.chapter = chapters[0]
                    }
                }
                
                Thread.onMainThread {
//                    self?.updatePicker()
                    self?.scripturePickerViewController?.updatePicker()
                    self?.showScripture()
                }
            }
        } else {
//            updatePicker()
            scripturePickerViewController?.updatePicker()
            showScripture()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
                                                            // In case it is embedded
        if let navigationController = navigationController, navigationController.topViewController == self, modalPresentationStyle != .popover {
            Alerts.shared.topViewController.append(navigationController)
        }
        
//        orientation = UIDevice.current.orientation
        
        addNotifications()
        
        navigationController?.isToolbarHidden = true

        if navigationController?.modalPresentationStyle == .popover {
            if let height = scripturePickerViewController?.scripturePicker.frame.height {
                preferredContentSize = CGSize(width:  view.frame.width,
                                              height: height + 60)
            }
        } else {
            
        }

        setupPicker()

        setupBarButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        if Alerts.shared.topViewController.last == navigationController {
            Alerts.shared.topViewController.removeLast()
        }

        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        setupBarButtons()
    }
    
//    func testament(_ book:String) -> String?
//    {
//        if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
//            return Constants.OT
//        } else
//            if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
//                return Constants.NT
//        }
//
//        return nil
//    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    }
    
//    func updatePicker()
//    {
//        if scripture?.selected.testament == nil {
//            scripture?.selected.testament = Constants.OT
//        }
//
//        guard let selectedTestament = scripture?.selected.testament else {
//            return
//        }
//
//        guard !selectedTestament.isEmpty else {
//            return
//        }
//
//        switch selectedTestament {
//        case Constants.OT:
//            scripture?.picker.books = Constants.OLD_TESTAMENT_BOOKS
//            break
//
//        case Constants.NT:
//            scripture?.picker.books = Constants.NEW_TESTAMENT_BOOKS
//            break
//
//        default:
//            break
//        }
//
//        if scripture?.selected.book == nil {
//            scripture?.selected.book = scripture?.picker.books?[0]
//        }
//
//        var maxChapters = 0
//        switch selectedTestament {
//        case Constants.OT:
//            if let index = scripture?.selected.book?.bookNumberInBible {
//                maxChapters = Constants.OLD_TESTAMENT_CHAPTERS[index]
//            }
//            break
//
//        case Constants.NT:
//            if let index = scripture?.selected.book?.bookNumberInBible {
//                maxChapters = Constants.NEW_TESTAMENT_CHAPTERS[index - Constants.OLD_TESTAMENT_BOOKS.count]
//            }
//            break
//
//        default:
//            break
//        }
//
//        var chapters = [Int]()
//        if maxChapters > 0 {
//            for i in 1...maxChapters {
//                chapters.append(i)
//            }
//        }
//        scripture?.picker.chapters = chapters
//
//        if scripture?.selected.chapter == 0, let chapter = scripture?.picker.chapters?[0] {
//            scripture?.selected.chapter = chapter
//        }
//
//        if includeVerses, let index = scripture?.selected.book?.bookNumberInBible, let chapter = scripture?.selected.chapter {
//            var maxVerses = 0
//            switch selectedTestament {
//            case Constants.OT:
//                maxVerses = Constants.OLD_TESTAMENT_VERSES[index][chapter]
//                break
//
//            case Constants.NT:
//                maxVerses = Constants.NEW_TESTAMENT_VERSES[index - Constants.OLD_TESTAMENT_BOOKS.count][chapter]
//                break
//
//            default:
//                break
//            }
//            var verses = [Int]()
//            if maxVerses > 0 {
//                for i in 1...maxVerses {
//                    verses.append(i)
//                }
//            }
//            scripture?.picker.verses = verses
//
//            if scripture?.selected.verse == 0, let verse = scripture?.picker.verses?[0] {
//                scripture?.selected.verse = verse
//            }
//        }
//
//        scripturePicker.reloadAllComponents()
//
////        guard let selectedTestament = scripture?.selected.testament else {
////            return
////        }
//
//        if let index = Constants.TESTAMENTS.firstIndex(of: selectedTestament) {
//            scripturePicker.selectRow(index, inComponent: 0, animated: false)
//        }
//
//        if let selectedBook = scripture?.selected.book, let index = scripture?.picker.books?.firstIndex(of: selectedBook) {
//            scripturePicker.selectRow(index, inComponent: 1, animated: false)
//        }
//
//        if let chapter = scripture?.selected.chapter, chapter > 0, let index = scripture?.picker.chapters?.firstIndex(of: chapter) {
//            scripturePicker.selectRow(index, inComponent: 2, animated: false)
//        }
//
//        guard includeVerses else {
//            return
//        }
//
//        if let verse = scripture?.selected.verse, verse > 0, let index = scripture?.picker.verses?.firstIndex(of: verse) {
//            scripturePicker.selectRow(index, inComponent: 3, animated: false)
//        }
//    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
//        updatePicker()
        
        updateReferenceLabel()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}
