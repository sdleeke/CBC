//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI


class ScriptureViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate, MFMailComposeViewControllerDelegate, PopoverTableViewControllerDelegate {
    var actionButton:UIBarButtonItem?
    var minusButton:UIBarButtonItem?
    var plusButton:UIBarButtonItem?

    var vc:UIViewController?
    
    var webViewController:WebViewController?
    
    var scripture:Scripture?
    
//    lazy var scripture:Scripture? = {
//        return Scripture(reference: nil)
//    }()
    
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var scripturePicker: UIPickerView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        
        let navCon = destination as? UINavigationController
        
        if navCon != nil {
            destination = navCon!.visibleViewController!
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
            if (scripture?.selected.testament != nil) {
                numberOfRows = scripture!.picker.books!.count
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if (scripture?.selected.testament != nil) && (scripture?.selected.book != nil) {
                numberOfRows = scripture!.picker.chapters!.count
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
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
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
    
    //    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    //
    //    }
    
//    func translateTestament(_ testament:String) -> String
//    {
//        var translation = Constants.EMPTY_STRING
//        
//        switch testament {
//        case Constants.OT:
//            translation = Constants.Old_Testament
//            break
//            
//        case Constants.NT:
//            translation = Constants.New_Testament
//            break
//            
//        default:
//            break
//        }
//        
//        return translation
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }
        
        label.font = UIFont(name: "System", size: 12.0)
        
        label.text = title(forRow: row, forComponent: component)
        
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
            if (scripture?.selected.testament != nil) {
                return scripture?.picker.books![row]
            }
            break
            
        case 2:
            if (scripture?.selected.testament != nil) {
                return "\(scripture!.picker.chapters![row])"
            }
            break
            
        case 3:
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
            
//            startingVerse = 0
            
            switch scripture!.selected.testament! {
            case Constants.OT:
                scripture?.picker.books = Constants.OLD_TESTAMENT_BOOKS
                break
                
            case Constants.NT:
                scripture?.picker.books = Constants.NEW_TESTAMENT_BOOKS
                break
                
            default:
                break
            }
            
            scripture?.selected.book = scripture?.picker.books?[0]
            
            updatePicker()
            
            scripture?.selected.chapter = scripture!.picker.chapters![0]

            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            //            pickerView.selectRow(0, inComponent: 3, animated: true)
            
            updateReferenceLabel()
            break
            
        case 1: // Book
            if (scripture?.selected.testament != nil) {
                scripture?.selected.book = scripture?.picker.books?[row]
                
//                startingVerse = 0

                updatePicker()

                scripture?.selected.chapter = scripture!.picker.chapters![0]

                pickerView.reloadAllComponents()
                
                pickerView.selectRow(0, inComponent: 2, animated: true)
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                
                updateReferenceLabel()
            }
            break
            
        case 2: // Chapter
            if (scripture?.selected.testament != nil) && (scripture?.selected.book != nil) {
                scripture?.selected.chapter = scripture!.picker.chapters![row]
                
//                startingVerse = 0
                
                pickerView.reloadAllComponents()
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                
                updateReferenceLabel()
            }
            break
            
        case 3: // Verse
            if (scripture?.selected.testament != nil) && (scripture?.selected.book != nil) && (scripture?.selected.chapter > 0) {
//                startingVerse = row + 1
                
                pickerView.reloadAllComponents()
                
                updateReferenceLabel()
            }
            break
            
        default:
            break
        }
        
        showScripture()
    }
    
    func clearView()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.title = nil
            self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            for view in self.view.subviews {
                view.isHidden = true
            }
        })
    }
    
    func setPreferredContentSize()
    {
        preferredContentSize = CGSize(width:  view.frame.width,//webViewController!.wkWebView!.scrollView.contentSize.width,
                                      height: webViewController!.wkWebView!.scrollView.contentSize.height + scripturePicker.frame.height + 60)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        if (self.view.window == nil) {
            return
        }

        //        print("Size: \(size)")

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//            print(self.view.frame.width,self.vc!.view!.frame.height)
            
            DispatchQueue.main.async(execute: { () -> Void in
//                self.preferredContentSize = CGSize(width:  self.view.frame.width,
//                                                   height: self.vc!.view!.frame.height)
                self.setPreferredContentSize()
            })
        }
    }
    
    func showScripture()
    {
        if let reference = self.scripture?.selected.reference {
            if self.scripture?.html?[reference] != nil {
                if let string = self.scripture?.html?[reference] {
                    self.webViewController?.html.string = string
                    _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                }
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    self.scripture?.load(reference)
                    return self.scripture?.html?[reference]
                }) { (data:Any?) in
                    if let string = data as? String {
                        self.webViewController?.html.string = string
                        _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                    } else {
                        var bodyString = "<!DOCTYPE html><html><body>"
                        
                        bodyString = bodyString + "Network error.  Scripture text unavailable."
                        
                        bodyString = bodyString + "</html></body>"
                        
                        if let string = insertHead(bodyString,fontSize:Constants.FONT_SIZE) {
                            self.webViewController?.html.string = string
                            _ = self.webViewController?.wkWebView?.loadHTMLString(string, baseURL: nil)
                        }
                    }
                }
            }
        }
    }
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()
        
        if self.navigationController?.modalPresentationStyle == .popover {
            actionMenu.append(Constants.Full_Screen)
        }
        
        if UIPrintInteractionController.isPrintingAvailable {
            actionMenu.append(Constants.Print)
        }
        
        if webViewController?.html.string != nil {
            actionMenu.append(Constants.Share)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            //                popover.navigationItem.title = Constants.Actions
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.strings = actionMenuItems()
            
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
    
    func decreaseFontSize()
    {
        webViewController?.decreaseFontSize()
    }
    
    func increaseFontSize()
    {
        webViewController?.increaseFontSize()
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
            case Constants.Full_Screen:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? WebViewController {
                    // Had to take out the lines below or the searchBar would become unresponsive. No idea why.
                    //                    DispatchQueue.main.async(execute: { () -> Void in
                    //                        self.dismiss(animated: true, completion: nil)
                    //                    })
                    
                    navigationController.modalPresentationStyle = .overFullScreen
                    navigationController.popoverPresentationController?.delegate = popover
                    
                    popover.navigationItem.title = self.navigationItem.title
                    
                    popover.html.fontSize = self.webViewController!.html.fontSize
                    popover.html.string = self.webViewController?.html.string
                    
                    popover.selectedMediaItem = self.webViewController?.selectedMediaItem
                    
                    popover.content = self.webViewController!.content
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(navigationController, animated: true, completion: nil)
                    })
                }
                break
                
            case Constants.Print:
                if webViewController?.html.string != nil, webViewController!.html.string!.contains(" href=") {
                    firstSecondCancel(viewController: self, title: "Remove Links?", message: "This can take some time.",
                                      firstTitle: "Yes",
                                      firstAction: {
                                        process(viewController: self, work: { () -> (Any?) in
                                            return stripLinks(self.webViewController?.html.string)
                                        }, completion: { (data:Any?) in
                                            printHTML(viewController: self, htmlString: data as? String)
                                        })
                    },
                                      secondTitle: "No",
                                      secondAction: {
                                        printHTML(viewController: self, htmlString: self.webViewController?.html.string)
                    },
                                      cancelAction: {}
                    )
                } else {
                    printHTML(viewController: self, htmlString: self.webViewController?.html.string)
                }
                break
                
            case Constants.Share:
                shareHTML(viewController: self, htmlString: webViewController!.html.string!)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func done()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupBarButtons()
    {
        actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(ScriptureViewController.actions))
        
        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(ScriptureViewController.increaseFontSize))
        
        plusButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.SHOW_FONT_SIZE)!], for: UIControlState())
        
        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(ScriptureViewController.decreaseFontSize))
        
        minusButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.SHOW_FONT_SIZE)!], for: UIControlState())
        
        navigationItem.setRightBarButtonItems([actionButton!,minusButton!,plusButton!], animated: true)
        
        if navigationController?.modalPresentationStyle == .overFullScreen {
            navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureViewController.done)), animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        preferredContentSize = CGSize(width:  view.frame.width,
                                      height: scripturePicker.frame.height + 60)
        
        setupBarButtons()
        
        if scripture?.selected.reference == nil, let reference = scripture?.reference, reference != Constants.Selected_Scriptures {
            DispatchQueue.global(qos: .background).async {
                self.scripture?.load(reference)
                
                // Take the first one in the Scripture reference?
                if let books:[String] = self.scripture?.xml.text?.keys.map({ (string:String) -> String in
                    return string
                }).sorted(by: { reference.range(of: $0)?.lowerBound < reference.range(of: $1)?.lowerBound }), books.count > 0 {
                    let book = books[0]
                    
                    self.scripture?.selected.testament = self.testament(book)
                    self.scripture?.selected.book = book
                    
                    if let chapters:[Int] = self.scripture?.xml.text?[book]?.keys.map({ (string:String) -> Int in
                        return Int(string)!
                    }).sorted(), chapters.count > 0 {
                        self.scripture?.selected.chapter = chapters[0]
                    }
                }
                
                // Sort by book and take the first one?
                //                if let books:[String] = scripture?.xml.text?.keys.map({ (string:String) -> String in
                //                    return string
                //                }).sorted(by: { bookNumberInBible($0) < bookNumberInBible($1) }), books.count > 0 {
                //                    let book = books[0].replacingOccurrences(of: "Psalms", with: "Psalm")
                //
                //                    scripture?.selected.testament = testament(book)
                //                    scripture?.selected.book = book
                //
                //                    if let chapters:[Int] = scripture?.xml.text?[book]?.keys.map({ (string:String) -> Int in
                //                        return Int(string)!
                //                    }).sorted(), chapters.count > 0 {
                //                        scripture?.selected.chapter = chapters[0]
                //                    }
                //                }
                
                // Below we are taking the LAST one.
                //                if let book = scripture?.xml.book?.replacingOccurrences(of: "Psalms", with: "Psalm") {
                //                    scripture?.selected.testament = testament(book)
                //                    scripture?.selected.book = book
                //                }
                //                scripture?.selected.chapter = Int(scripture!.xml.chapter!)!
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.updatePicker()
                    self.showScripture()
                })
            }
        } else {
            updatePicker()
            showScripture()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        saveSettings()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

//        navigationController?.preferredContentSize = CGSize(width:  view.frame.width,
//                                                            height: vc!.view.frame.height)

        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        
        //        navigationController?.navigationBar.backItem?.title = Constants.Back
        //        navigationItem.hidesBackButton = false
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func testament(_ book:String) -> String
    {
        if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
            return Constants.OT
        } else
            if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
                return Constants.NT
        }
        
        return Constants.EMPTY_STRING
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureViewController.setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
        }
        
        //        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
//        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(ScriptureIndexViewController.actions)), animated: true) //
    }
    
    func updatePicker()
    {
        //                print(selectedTestament)
        //                print(selectedBook)
        //                print(selectedChapter)
        
        if scripture?.selected.testament == nil {
            scripture?.selected.testament = Constants.OT
        }
        
        if let selectedTestament = scripture?.selected.testament {
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
            
            if scripture?.selected.chapter == 0 {
                scripture?.selected.chapter = scripture!.picker.chapters![0]
            }
        }

        scripturePicker.reloadAllComponents()
        
        if let selectedTestament = scripture?.selected.testament {
            if let index = Constants.TESTAMENTS.index(of: selectedTestament) {
                scripturePicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            if let selectedBook = scripture?.selected.book, let index = scripture?.picker.books?.index(of: selectedBook) {
                scripturePicker.selectRow(index, inComponent: 1, animated: false)
            }
            
            if scripture?.selected.chapter > 0, let index = scripture?.picker.chapters?.index(of: scripture!.selected.chapter) {
                scripturePicker.selectRow(index, inComponent: 2, animated: false)
            }
            
//            if startingVerse > 0, let index = scripturePickerData.startingVerses?.index(of: startingVerse) {
//                scripturePicker.selectRow(index, inComponent: 3, animated: false)
//            }
        }
    }
    
    func updateActionMenu()
    {
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateUI()
    {
        navigationController?.setToolbarHidden(scripture?.selected.book != nil, animated: true)
        
        updateActionMenu()
        
        updatePicker()
        
        updateReferenceLabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
