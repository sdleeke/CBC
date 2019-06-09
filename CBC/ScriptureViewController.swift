//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

extension ScriptureViewController : UIActivityItemSource
{
    func share()
    {
        guard let html = webViewController?.html.string else {
            return
        }
        
        // Must be on main thread.
        let print = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = CBCActivityViewController(activityItems:[self,html,print] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
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
            self.alert(title: "Not Main Thread", message: "ScriptureViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
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
                    self.firstSecondCancel(title: "Remove Links?", // message: nil, //"This can take some time.",
                        firstTitle: Constants.Strings.Yes,
                        firstAction: {
                            // test:(()->(Bool))?
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
                self.process(disableEnable: false, work: { (test:(()->(Bool))?) -> (Any?) in
                    if #available(iOS 12.0, *) {
                        return self.scripture?.text(self.scripture?.reference)?.nlNameAndLexicalTypesMarkup(annotated:true, test:test)
                    } else {
                        // Fallback on earlier versions
                        return self.scripture?.text(self.scripture?.reference)?.nsNameAndLexicalTypesMarkup(annotated:true, test:test)
                    }
                }) { [weak self] (data:Any?, test:(()->(Bool))?) in
                    guard test?() != true else {
                        return
                    }
                    
                    guard let data = data else {
                        Alerts.shared.alert(title:"Lexical Analysis Not Available")
                        return
                    }
                    
                    if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? WebViewController {
                        popover.navigationItem.title = self?.scripture?.reference?.qualifier(Constants.Strings.Lexical_Analysis)
                        navigationController.isNavigationBarHidden = false
                        
                        navigationController.modalPresentationStyle = .overCurrentContext
                        navigationController.popoverPresentationController?.delegate = self
                        
                        popover.html.string = data as? String
                        popover.content = .html
                        
                        self?.present(navigationController, animated: true, completion: nil)
                    }
                }
                break
                
            case Constants.Strings.Search:
                self.searchAlert(title: "Search", searchText:webViewController?.searchText, searchAction:  { (alert:UIAlertController) -> (Void) in
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
                    
                    popover.allowsSelection = false
                    
                    popover.navigationItem.title = scripture?.reference?.qualifier(Constants.Strings.Word_Picker)
                    
                    popover.stringsFunction = { [weak self] in
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
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
                    
                    popover.cloudTitle = self.scripture?.reference?.qualifier(Constants.Strings.Word_Cloud)
                    
                    if let mediaItem = mediaItem {
                        popover.cloudTitle = mediaItem.title?.qualifier(Constants.Strings.Word_Cloud)
                        
                        popover.cloudString = self.webViewController?.bodyHTML?.html2String
                        
                        popover.cloudWordDictsFunction = { [weak self] in
                            let words:[[String:Any]]? = self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (key:String, value:Int) -> [String:Any] in
                                return ["word":key,"count":value,"selected":true]
                            })
                            
                            return words
                        }
                    }
                    
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
                
            case Constants.Strings.Word_Index:
                self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                    return self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                        return "\(word) (\(count))"
                    }).sorted().tableHTML(title:self?.scripture?.reference?.qualifier(Constants.Strings.Word_Index), test:test)
                }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                    self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: self?.scripture?.reference?.qualifier(Constants.Strings.Word_Index), htmlString: data as? String)
                })
                break
                
            case Constants.Strings.Words:
                self.selectWord(title:scripture?.reference?.qualifier(Constants.Strings.Words), purpose:.selectingWord, allowsSelection:false, stringsFunction: { [weak self] in
                    // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                    return self?.webViewController?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                        return "\(word) (\(count))"
                    }).sorted()
                })
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

//extension ScriptureViewController : MFMailComposeViewControllerDelegate
//{
//    // MARK: MFMailComposeViewControllerDelegate Method
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        controller.dismiss(animated: true, completion: nil)
//    }
//}

/**
 For displaying Scripture
 */
class ScriptureViewController : CBCViewController
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
            scripturePickerViewController?.scripture = scripture
        }
    }
    
    @IBOutlet weak var directionLabel: UILabel!
    
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
    
    @objc func actions()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureViewController:actions", completion: nil)
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
            
            present(navigationController, animated: true, completion:  nil)
        }
    }
    
    func updateReferenceLabel()
    {
//        print(scripture?.reference)
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
        Thread.onMain {
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
            Thread.onMain {
                self.setPreferredContentSize()
            }
        }
    }
    
    func showScripture()
    {
        guard let reference = self.scripture?.picked.reference else {
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
                
                self.webViewController?.bodyHTML = self.webViewController?.html.string
                
                if let url = self.webViewController?.html.fileURL {
                    self.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }

                self.webViewController?.view.isHidden = false
            }
        } else {
            // test:(()->(Bool))?
            self.process(work: { [weak self] () -> (Any?) in
                self?.scripture?.load() // reference
                return self?.scripture?.html?[reference]
            }) { [weak self] (data:Any?) in
                if let string = data as? String {
                    self?.webViewController?.html.string = string.stripHead.insertHead(fontSize:self?.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                    
                    self?.webViewController?.bodyHTML = self?.webViewController?.html.string
                    
                    if let url = self?.webViewController?.html.fileURL {
                        self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }
                } else {
                    var bodyString = "<!DOCTYPE html><html><body>"
                    
                    bodyString = bodyString + "Network error.  Scripture text unavailable."
                    
                    bodyString = bodyString + "</body></html>"

                    self?.webViewController?.html.string = bodyString.insertHead(fontSize:self?.webViewController?.html.fontSize ?? Constants.FONT_SIZE)
                    
                    self?.webViewController?.bodyHTML = self?.webViewController?.html.string

                    if let url = self?.webViewController?.html.fileURL {
                        self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }
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
        
        popover.navigationItem.title = self.scripture?.description

        popover.scripture = scripture
        
        popover.navigationController?.isNavigationBarHidden = false
        
        self.presentingViewController?.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func resetScripture()
    {
        scripture?.picked.clear()
        scripture?.reference = mediaItem?.scriptureReference
        setupPicker()
        navigationController?.isToolbarHidden = true
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
            
            if (scripture?.picked.testament != testament) ||  (scripture?.picked.book != book) || (scripture?.picked.chapter != chapter) {
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
    
    func addNotifications()
    {
//        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
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
        if scripture?.picked.reference == nil, let reference = scripture?.reference, let books = reference.books, books.count > 0 {
            webViewController?.view.isHidden = true
            
            operationQueue.addOperation { [weak self] in
                self?.scripture?.reference = reference // Why?
                self?.scripture?.load()
                
                if let books = self?.scripture?.booksChaptersVerses?.books?.sorted(by: { self?.scripture?.reference?.range(of: $0)?.lowerBound < self?.scripture?.reference?.range(of: $1)?.lowerBound }) {
                    let book = books[0]
                    
                    self?.scripture?.picked.testament = book.testament.translateTestament
                    self?.scripture?.picked.book = book
                    
                    if let chapters = self?.scripture?.booksChaptersVerses?[book]?.keys.sorted() {
                        self?.scripture?.picked.chapter = chapters[0]
                    }
                }
                
                Thread.onMain {
                    self?.scripturePickerViewController?.updatePicker()
                    self?.showScripture()
                }
            }
        } else {
            scripturePickerViewController?.updatePicker()
            showScripture()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
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

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        updateReferenceLabel()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}
