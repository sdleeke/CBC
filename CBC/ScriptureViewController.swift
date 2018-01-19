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

extension ScriptureViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate

//    func shareHTML(_ htmlString:String?)
//    {
//        guard let htmlString = htmlString else {
//            return
//        }
//        
//        let print = UIMarkupTextPrintFormatter(markupText: htmlString)
//        let margin:CGFloat = 0.5 * 72
//        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
//
//        activityViewController = UIActivityViewController(activityItems:[stripHTML(htmlString),htmlString,print] , applicationActivities: nil)
//        
//        // exclude some activity types from the list (optional)
//        
//        activityViewController?.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
//        
//        activityViewController?.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//        
//        if let activityViewController = self.activityViewController {
//            // present the view controller
//            Thread.onMainThread() {
//                self.present(activityViewController, animated: true, completion: nil)
//            }
//        }
//    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        dismiss(animated: true, completion: nil)
        
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
                    firstSecondCancel(viewController: self, title: "Remove Links?", message: nil, //"This can take some time.",
                                      firstTitle: "Yes",
                                      firstAction: {
                                        process(viewController: self, work: { [weak self] () -> (Any?) in
                                            return stripLinks(self?.webViewController?.html.string)
                                        }, completion: { [weak self] (data:Any?) in
                                            if let vc = self {
                                                printHTML(viewController: vc, htmlString: data as? String)
                                            }
                                        })
                    }, firstStyle: .default,
                                      secondTitle: "No",
                                      secondAction: {
                                        printHTML(viewController: self, htmlString: self.webViewController?.html.string)
                    }, secondStyle: .default,
                                      cancelAction: {}
                    )
                } else {
                    printHTML(viewController: self, htmlString: self.webViewController?.html.string)
                }
                break
                
//            case Constants.Strings.Share:
//                shareHTML(viewController: self, htmlString: webViewController?.html.string)
//                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
}

extension ScriptureViewController : UIPickerViewDataSource
{
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var numberOfRows = 1
        
        switch component {
        case 0:
            numberOfRows = 2 // N.T. or O.T.
            break
            
        case 1:
            if scripture?.selected.testament != nil, let books = scripture?.picker.books {
                numberOfRows = books.count
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if  scripture?.selected.testament != nil,
                scripture?.selected.book != nil,
                let chapters = scripture?.picker.chapters {
                numberOfRows = chapters.count
            } else {
                numberOfRows = 0 // number of chapters in book
            }
            break
            
        case 3:
            if scripture?.selected.chapter > 0 {
                numberOfRows = 1 // number of verses in chapter
            } else {
                numberOfRows = 0 // number of verses in chapter
            }
            break
            
        default:
            break
        }
        
        return numberOfRows
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = (view as? UILabel) ?? UILabel()
        
        if let title = title(forRow: row, forComponent: component) {
            label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.normal)
        }
        
        return label
    }
    
    func title(forRow row:Int, forComponent component:Int) -> String?
    {
        switch component {
        case 0:
            if row == 0 {
                return Constants.OT
            }
            if row == 1 {
                return Constants.NT
            }
            break
            
        case 1:
            guard scripture?.selected.testament != nil else {
                break
            }
            
            if let book = scripture?.picker.books?[row] {
                return book
            }
            break
            
        case 2:
            guard scripture?.selected.testament != nil else {
                break
            }
            
            guard scripture?.selected.book != nil else {
                break
            }

            if let chapters = scripture?.picker.chapters {
                return "\(chapters[row])"
            }
            break
            
        case 3:
            guard scripture?.selected.testament != nil else {
                break
            }
            
            guard scripture?.selected.book != nil else {
                break
            }
            
            if scripture?.selected.chapter > 0 {
                return "1"
            }
            break
            
        default:
            break
        }
        
        return Constants.EMPTY_STRING
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return title(forRow: row,forComponent: component)
    }
}

extension ScriptureViewController : UIPickerViewDelegate
{
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
    {
        switch component {
        case 0:
            return 50
            
        case 1:
            return 175
            
        case 2:
            return 35
            
        case 3:
            return 35
            
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch component {
        case 0: // Testament
            switch row {
            case 0:
                scripture?.selected.testament = Constants.OT
                break
                
            case 1:
                scripture?.selected.testament = Constants.NT
                break
                
            default:
                break
            }
            
            if let testament = scripture?.selected.testament {
                switch testament {
                case Constants.OT:
                    scripture?.picker.books = Constants.OLD_TESTAMENT_BOOKS
                    break
                    
                case Constants.NT:
                    scripture?.picker.books = Constants.NEW_TESTAMENT_BOOKS
                    break
                    
                default:
                    break
                }
            }
            
            scripture?.selected.book = scripture?.picker.books?[0]
            
            updatePicker()
            
            if let chapter = scripture?.picker.chapters?[0] {
                scripture?.selected.chapter = chapter
            }
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            updateReferenceLabel()
            break
            
        case 1: // Book
            guard scripture?.selected.testament != nil else {
                break
            }
            
            scripture?.selected.book = scripture?.picker.books?[row]
            
            updatePicker()
            
            if let chapter = scripture?.picker.chapters?[0] {
                scripture?.selected.chapter = chapter
            }
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            updateReferenceLabel()
            break
            
        case 2: // Chapter
            guard scripture?.selected.testament != nil else {
                break
            }

            guard scripture?.selected.book != nil else {
                break
            }
            
            if let chapter = scripture?.picker.chapters?[row] {
                scripture?.selected.chapter = chapter
            }
            
            pickerView.reloadAllComponents()
            
            updateReferenceLabel()
            break
            
        case 3: // Verse
            guard scripture?.selected.testament != nil else {
                break
            }
            
            guard scripture?.selected.book != nil else {
                break
            }
            
            guard scripture?.selected.chapter > 0 else {
                break
            }
            
            pickerView.reloadAllComponents()
            
            updateReferenceLabel()
            break
            
        default:
            break
        }
        
        showScripture()
    }
}

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
    var popover : PopoverTableViewController?
    
    var minusButton:UIBarButtonItem?
    var plusButton:UIBarButtonItem?

    var vc:UIViewController?
    
    var webViewController:WebViewController?
    
    var scripture:Scripture?
    
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var scripturePicker: UIPickerView!
    
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
                    
                    webViewController?.html.string = ""
                    webViewController?.content = .html
                }
                break
                
            default:
                break
            }
        }
    }
    
    func updateReferenceLabel()
    {

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
        Thread.onMainThread() {
            self.navigationItem.title = nil
            self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            for view in self.view.subviews {
                view.isHidden = true
            }
        }
    }
    
    func setPreferredContentSize()
    {
        if let widthView = presentingViewController?.view ?? view, let wkWebView = webViewController?.wkWebView {
            preferredContentSize = CGSize(  width:  widthView.frame.width,
                                            height: wkWebView.scrollView.contentSize.height + scripturePicker.frame.height + 60)
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
            Thread.onMainThread() {
                self.setPreferredContentSize()
            }
        }
    }
    
    func showScripture()
    {
        if let reference = self.scripture?.selected.reference {
            scripture?.reference = reference
            if self.scripture?.html?[reference] != nil {
                if let string = self.scripture?.html?[reference] {
                    self.webViewController?.html.string = string
                    
                    if let url = self.webViewController?.html.fileURL {
                        self.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }

                    self.webViewController?.view.isHidden = false

//                    _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                }
            } else {
                process(viewController: self, work: { [weak self] () -> (Any?) in
                    self?.scripture?.load() // reference
                    return self?.scripture?.html?[reference]
                }) { [weak self] (data:Any?) in
                    if let string = data as? String {
                        self?.webViewController?.html.string = string
                        
                        if let url = self?.webViewController?.html.fileURL {
                            self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                        }

//                        _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                    } else {
                        var bodyString = "<!DOCTYPE html><html><body>"
                        
                        bodyString = bodyString + "Network error.  Scripture text unavailable."
                        
                        bodyString = bodyString + "</html></body>"
                        
                        if let string = insertHead(bodyString,fontSize:Constants.FONT_SIZE) {
                            self?.webViewController?.html.string = string
                            
                            if let url = self?.webViewController?.html.fileURL {
                                self?.webViewController?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                            }

//                            _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                        }
                    }

                    self?.webViewController?.view.isHidden = false
                }
            }
        }
    }
    
    func decreaseFontSize()
    {
        webViewController?.decreaseFontSize()
    }
    
    func increaseFontSize()
    {
        webViewController?.increaseFontSize()
    }
    
    func done()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupBarButtons()
    {
        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(ScriptureViewController.increaseFontSize))
        plusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(ScriptureViewController.decreaseFontSize))
        minusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        if let minusButton = minusButton, let plusButton = plusButton {
            navigationItem.setRightBarButtonItems([minusButton,plusButton], animated: true)
        }
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .formSheet:
                fallthrough
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureViewController.done)), animated: true)

            default:
                break
            }
        }
    }
    
    var ptvc:PopoverTableViewController?
    
    var activityViewController:UIActivityViewController?

    var orientation : UIDeviceOrientation?
    
    func deviceOrientationDidChange()
    {
        guard let orientation = orientation else {
            return
        }
        
        func action()
        {
            ptvc?.dismiss(animated: false, completion: nil)
            activityViewController?.dismiss(animated: false, completion: nil)
        }
        
        // Dismiss any popover
        switch orientation {
        case .faceUp:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .faceDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeLeft:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeRight:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portrait:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portraitUpsideDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .unknown:
            break
        }
        
        switch UIDevice.current.orientation {
        case .faceUp:
            break
            
        case .faceDown:
            break
            
        case .landscapeLeft:
            self.orientation = UIDevice.current.orientation
            break
            
        case .landscapeRight:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portrait:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portraitUpsideDown:
            self.orientation = UIDevice.current.orientation
            break
            
        case .unknown:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        orientation = UIDevice.current.orientation
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ScriptureViewController.setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
        
        navigationController?.isToolbarHidden = true

        preferredContentSize = CGSize(width:  view.frame.width,
                                      height: scripturePicker.frame.height + 60)
        
        setupBarButtons()
        
        if scripture?.selected.reference == nil, let reference = scripture?.reference, let books = booksFromScriptureReference(reference), books.count > 0 {
            webViewController?.view.isHidden = true
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.scripture?.reference = reference
                self?.scripture?.load() // reference
                
                if let books = self?.scripture?.booksChaptersVerses?.data?.keys.sorted(by: { self?.scripture?.reference?.range(of: $0)?.lowerBound < self?.scripture?.reference?.range(of: $1)?.lowerBound }) {
                    let book = books[0]
                    
                    self?.scripture?.selected.testament = self?.testament(book)
                    self?.scripture?.selected.book = book
                    
                    if let chapters = self?.scripture?.booksChaptersVerses?.data?[book]?.keys.sorted() {
                        self?.scripture?.selected.chapter = chapters[0]
                    }
                }
                
                Thread.onMainThread() {
                    self?.updatePicker()
                    self?.showScripture()
                }
            }
        } else {
            updatePicker()
            showScripture()
        }
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

    }
    
    func testament(_ book:String) -> String?
    {
        if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
            return Constants.OT
        } else
            if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
                return Constants.NT
        }
        
        return nil
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

    }
    
    func updatePicker()
    {
        if scripture?.selected.testament == nil {
            scripture?.selected.testament = Constants.OT
        }
        
        guard let selectedTestament = scripture?.selected.testament, !selectedTestament.isEmpty else {
            return
        }
        
        switch selectedTestament {
        case Constants.OT:
            scripture?.picker.books = Constants.OLD_TESTAMENT_BOOKS
            break
            
        case Constants.NT:
            scripture?.picker.books = Constants.NEW_TESTAMENT_BOOKS
            break
            
        default:
            break
        }

        if scripture?.selected.book == nil {
            scripture?.selected.book = scripture?.picker.books?[0]
        }
        
        var maxChapters = 0
        switch selectedTestament {
        case Constants.OT:
            if let index = bookNumberInBible(scripture?.selected.book) {
                maxChapters = Constants.OLD_TESTAMENT_CHAPTERS[index]
            }
            break
            
        case Constants.NT:
            if let index = bookNumberInBible(scripture?.selected.book) {
                maxChapters = Constants.NEW_TESTAMENT_CHAPTERS[index - Constants.OLD_TESTAMENT_BOOKS.count]
            }
            break
            
        default:
            break
        }

        var chapters = [Int]()
        for i in 1...maxChapters {
            chapters.append(i)
        }
        scripture?.picker.chapters = chapters
            
        if scripture?.selected.chapter == 0, let chapter = scripture?.picker.chapters?[0] {
            scripture?.selected.chapter = chapter
        }

        scripturePicker.reloadAllComponents()
        
        if let selectedTestament = scripture?.selected.testament {
            if let index = Constants.TESTAMENTS.index(of: selectedTestament) {
                scripturePicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            if let selectedBook = scripture?.selected.book, let index = scripture?.picker.books?.index(of: selectedBook) {
                scripturePicker.selectRow(index, inComponent: 1, animated: false)
            }
            
            if let chapter = scripture?.selected.chapter, chapter > 0, let index = scripture?.picker.chapters?.index(of: chapter) {
                scripturePicker.selectRow(index, inComponent: 2, animated: false)
            }
        }
    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        updatePicker()
        
        updateReferenceLabel()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}
