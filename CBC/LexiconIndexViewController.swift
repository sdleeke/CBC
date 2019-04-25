//
//  LexiconIndexViewController.swift
//  CBC
//
//  Created by Steve Leeke on 2/2/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

extension LexiconIndexViewController : UIAdaptivePresentationControllerDelegate
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

extension LexiconIndexViewController : PopoverPickerControllerDelegate
{
    //  MARK: PopoverPickerControllerDelegate

    func stringPicked(_ string: String?, purpose:PopoverPurpose?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:stringPicked",completion:nil)
            return
        }
        
        self.dismiss(animated: true, completion: nil)
        self.tableView.setEditing(false, animated: true)
        self.wordsTableViewController.selectString(string, scroll: true, select: true)
        
        searchText = string
    }
}

extension LexiconIndexViewController : PopoverTableViewControllerDelegate
{
    //  MARK: PopoverTableViewControllerDelegate

    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
   func actionMenu(action: String?,mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:actionMenu", completion: nil)
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
//        case Constants.Strings.Sorting:
//            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
//                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
//
//                navigationController.popoverPresentationController?.delegate = self
//
//                navigationController.popoverPresentationController?.permittedArrowDirections = .up
//                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//
//                popover.navigationItem.title = "Select"
//                navigationController.isNavigationBarHidden = false
//
//                popover.delegate = self
//                popover.purpose = .selectingSorting
//                popover.stringSelected = self.wordsTableViewController.section.method
//
//                popover.section.strings = [Constants.Sort.Alphabetical,Constants.Sort.Frequency]
//
//                present(navigationController, animated: true, completion: nil)
//            }
//            break
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                popover.navigationItem.title = "Select"
                navigationController.isNavigationBarHidden = false

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
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Strings.Word_Picker
                
                popover.delegate = self
                
//                popover.actionTitle = Constants.Strings.Expanded_View
//                
//                ////////////////////////////////////////////////////////////////////////////////////////
//                //          WEAK POPOVER IS CRUCIAL TO AVOID A RETAIL CYCLE
//                ////////////////////////////////////////////////////////////////////////////////////////
//                popover.action = { [weak popover] (String) in
//                    popover?.process(work: { [weak self] () -> (Any?) in
//                        Thread.onMainThread {
//                            popover?.navigationItem.rightBarButtonItem?.isEnabled = false
//                        }
//                        
//                        return popover?.stringTree?.html
//                    }, completion: { [weak self] (data:Any?) in
//                        popover?.presentHTMLModal(mediaItem: nil, style: .fullScreen, title: Constants.Strings.Expanded_View, htmlString: data as? String)
//
//                        Thread.onMainThread {
//                            popover?.navigationItem.rightBarButtonItem?.isEnabled = true
//                        }
//                    })
//                }

                popover.lexicon = self.lexicon

//                popover.stringTree?.lexicon = self.lexicon
                
//                popover.stringTree = StringTree(lexicon:lexicon, stringsFunction: { [weak self] in
//                    return self?.lexicon?.stringsFunction?()
//                }, incremental:true)

//                popover.stringTree?.completed = false // The user could have used search in LIVC wordsTable PTVC
                // This really defeats the purpose of saving the stringTree in the lexicon.
                // But it covers over the lost words problem of incremental updates by forcing a new stringTree each
                // time it is opened.  Which is also slow!
                
                // AND because LIVC words table activeWords may be FEWER than last time we can't keep anything from
                // past string trees!
                
                // mediaListGroupSort?.lexicon?.tokens
//                popover.strings = activeWords

                popover.stringsFunction = lexicon?.stringsFunction
//                { [weak self] in
//                    return self?.activeWords
//                }
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Word_List:
            self.process(work: { [weak self] () -> (Any?) in
                // Use setupMediaItemsHTML to also show the documents these words came from - and to allow linking from words to documents.
                // The problem is that for lots of words (and documents) this gets to be a very, very large HTML documents

                // SHOULD ONLY BE activeWords
                
//                return self?.lexicon?.wordsHTML
                return self?.activeWordsHTML
            }, completion: { [weak self] (data:Any?) in
                // preferredModalPresentationStyle(viewController: self)
                self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: "Word List", htmlString: data as? String)
            })
            break
            
        case "Stop":
            let alert = UIAlertController(  title: "Confirm Stopping Lexicon Build",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: {
                (action : UIAlertAction!) -> Void in
                self.lexicon?.stop()
                if self.navigationController?.visibleViewController == self {
                    self.navigationController?.popViewController(animated: true)
                }
                Alerts.shared.alert(title: "Lexicon Build Stopped")
            })
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            alert.addAction(noAction)
            
            self.present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.View_List:
            self.process(work: { [weak self] () -> (Any?) in
                if self?.results?.html?.string == nil {
                    self?.results?.html?.string = self?.setupMediaItemsHTMLLexicon(includeURLs:true, includeColumns:true)
                }
                
                return self?.results?.html?.string
            }, completion: { [weak self] (data:Any?) in
                if let searchText = self?.searchText, let vc = self {
                    vc.presentHTMLModal(mediaItem: nil, style: .overFullScreen, title: "Lexicon Index For: \(searchText)", htmlString: data as? String)
                }
            })
            break
            
        default:
            break
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:rowClickedAtIndex", completion: nil)
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
        case .selectingSorting:
            dismiss(animated: true, completion: nil)

            wordsTableViewController.section.method = string
            
            switch string {
            case Constants.Sort.Alphabetical:
                wordsTableViewController.section.showIndex = true
                break
                
            case Constants.Sort.Frequency:
                wordsTableViewController.section.showIndex = false
                break
                
            default:
                break
            }
            
            wordsTableViewController.section.strings = wordsTableViewController.section.function?(wordsTableViewController.section.method,wordsTableViewController.section.strings)
            
            wordsTableViewController.tableView.reloadData()
            break
            
        case .selectingSection:
            dismiss(animated: true, completion: nil)
            
            if let headerStrings = results?.section?.headerStrings {
                var i = 0
                for headerString in headerStrings {
                    if headerString == string {
                        break
                    }
                    
                    i += 1
                }
                
                let indexPath = IndexPath(row: 0, section: i)
                
//                if !(indexPath.section < tableView.numberOfSections) {
//                    NSLog("indexPath section ERROR in LexiconIndex .selectingSection")
//                    NSLog("Section: \(indexPath.section)")
//                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
//                    break
//                }
//
//                if !(indexPath.row < tableView.numberOfRows(inSection: indexPath.section)) {
//                    NSLog("indexPath row ERROR in LexiconIndex .selectingSection")
//                    NSLog("Section: \(indexPath.section)")
//                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
//                    NSLog("Row: \(indexPath.row)")
//                    NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
//                    break
//                }
                
                //Can't use this reliably w/ variable row heights.
                if tableView.isValid(indexPath) {
                    tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                }
            }
            break
            
        case .selectingLexicon:
            var text = string
            
            if let range = text.range(of: " (") {
                text = String(string[..<range.lowerBound])
            }

            var bounds = view.bounds
            
            if #available(iOS 11.0, *) {
                bounds = view.bounds.inset(by: view.safeAreaInsets)
            } else {
                // Fallback on earlier versions
            }
            
            guard searchText != text.uppercased() else {
                searchText = nil
                if let indexPath = wordsTableViewController.tableView.indexPathForSelectedRow {
                    wordsTableViewController.tableView.deselectRow(at: indexPath, animated: true)
                }
                break
            }
            
            searchText = text.uppercased()
            
            Thread.onMainThread {
                self.tableView.setEditing(false, animated: true)
            }
//
//            if tableViewHeightConstraint.constant == 0 {
//                tableViewHeightConstraint.constant = tableView.rowHeight + (tableView.headerView(forSection: 0)?.bounds.height ?? 0) // + ((navigationController?.isToolbarHidden ?? true) ? 0 : (navigationController?.toolbar.bounds.height ?? 0))
//            }
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)

            actionMenu(action:string,mediaItem:mediaItem)
            break
            
        case .selectingCellAction:
            dismiss(animated: true, completion: nil)
            
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download(background: true)
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
            
        case .selectingTimingIndexWord:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?["TIMINGINDEXWORD"]?.selectedMediaItem
                popover.transcript = self.popover?["TIMINGINDEXWORD"]?.transcript
                
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
                popover.section.indexStringsTransform =  { (string:String?) -> String? in
                    return string?.century
                } //century
                popover.section.indexHeadersTransform = { (string:String?) -> String? in
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
                
//                popover.editActionsAtIndexPath = popover.transcript?.rowActions
                
                self.popover?["TIMINGINDEXWORD"]?.navigationController?.pushViewController(popover, animated: true)
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

extension LexiconIndexViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension LexiconIndexViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class LexiconIndexViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class LexiconIndexViewController : UIViewController
{
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setTableViewHeightConstraint(change:0)
//            if self.tableViewHeightConstraint.isActive {
//                self.tableViewHeightConstraint.constant = CGFloat(UserDefaults.standard.double(forKey: "LEXICON INDEX RESULTS TABLE VIEW HEIGHT"))
//            }
            self.updateLocateButton()
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        // This wrecks havoc on push.  Not sure why it was put here.
//        setTableViewHeightConstraint(change:0)
    }
    
    func setTableViewHeightConstraint(change:CGFloat)
    {
        guard tableViewHeightConstraint.isActive else {
            return
        }
        
        var constant:CGFloat = tableViewHeightConstraint.constant
        
        if searchText == nil {
            constant = 0
        }
        
        updateToolbar()

        var maxHeight:CGFloat = 200
        
        var bounds = view.bounds
        
        if #available(iOS 11.0, *) {
            bounds = view.bounds.inset(by: view.safeAreaInsets)
        } else {
            // Fallback on earlier versions
        }
        
        let wordsTableViewControllerSpace = bounds.height - container.frame.origin.y
        
        if searchText == nil {
            maxHeight = wordsTableViewControllerSpace
        }
        
        let newConstraintConstant = constant + change
        
        let resultsOverhead = searchText != nil ? locateView.frame.height : 0
        
        let resultsMinimum = searchText != nil ? (tableView.rowHeight  + (tableView.headerView(forSection: 0)?.bounds.height ?? 0)) : 0
        
        
//        tableViewHeightConstraint.constant = tableView.rowHeight + (tableView.headerView(forSection: 0)?.bounds.height ?? 0) // + ((navigationController?.isToolbarHidden ?? true) ? 0 : (navigationController?.toolbar.bounds.height ?? 0))

        
        let resultsTableViewSpace = bounds.height - resultsOverhead
        
        if (newConstraintConstant >= resultsMinimum) && (newConstraintConstant <= resultsTableViewSpace) {
            constant = newConstraintConstant
        } else {
            if newConstraintConstant < resultsMinimum {
                constant = resultsMinimum
            }
            
            if newConstraintConstant > resultsTableViewSpace {
                constant = resultsTableViewSpace
            }
        }
        
        wordsTableViewControllerHeightConstraint.constant = max(wordsTableViewControllerSpace - (constant + resultsOverhead),maxHeight) // ((view.bounds.height - constant) + minimum)

        locateButton.isEnabled = maxHeight <= (wordsTableViewControllerSpace - (constant + resultsOverhead))
        
        tableViewHeightConstraint.constant = constant

        if change != 0 {
            // If the change is non-zero we need to update the locate button and save the constraint height.
            updateLocateButton()
            UserDefaults.standard.set(tableViewHeightConstraint.constant, forKey: "LEXICON INDEX RESULTS TABLE VIEW HEIGHT")
            UserDefaults.standard.synchronize()
        }

        updateToolbar()

        view.setNeedsLayout()
        view.layoutSubviews()
    }
    
    func resetConstraint()
    {
        
        var bounds = view.bounds
        
        if #available(iOS 11.0, *) {
            bounds = view.bounds.inset(by: view.safeAreaInsets)
        } else {
            // Fallback on earlier versions
        }
        
        tableViewHeightConstraint.constant = bounds.height / 2
        setTableViewHeightConstraint(change: 0)
    }
    
    func zeroConstraint()
    {
        tableViewHeightConstraint.constant = 0
        
        view.setNeedsLayout()
        view.layoutSubviews()
    }
    
    @IBOutlet weak var locateView: UIView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    {
        didSet {
            tableViewHeightConstraint.constant = CGFloat(UserDefaults.standard.double(forKey: "LEXICON INDEX RESULTS TABLE VIEW HEIGHT"))
        }
    }
    @IBOutlet weak var wordsTableViewControllerHeightConstraint: NSLayoutConstraint!
    {
        didSet {

        }
    }
    
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBAction func panGestureAction(_ pan: UIPanGestureRecognizer)
    {
        switch pan.state {
        case .began:
            break
            
        case .ended:
            break
            
        case .changed:
            let translation = pan.translation(in: pan.view)
            let change = -translation.y
            if change != 0 {
                pan.setTranslation(CGPoint.zero, in: pan.view)
                setTableViewHeightConstraint(change:change)
            }
            break
            
        default:
            break
        }
    }
    
    var mediaListGroupSort:MediaListGroupSort?
    {
        didSet {
            lexicon?.stringsFunction = { [weak self] in
                return self?.activeWords
            }
            lexicon?.stringTreeFunction = { [weak self] in
                return self?.lexicon?.stringTree(self?.wordsTableViewController.searchText)
            }
        }
    }
    
    var root:StringNode?
    
    private var lexicon:Lexicon?
    {
        get {
            return mediaListGroupSort?.lexicon
        }
    }
    
//    lazy var stringTree : StringTree? = { [weak self] in
//        return StringTree(lexicon:lexicon, stringsFunction: { [weak self] in
//            return self?.lexicon?.stringsFunction?()
//            }, incremental:true)
//    }()

    // Doesn't help during lexicon building because activeWordsString may change during lexicon updates
//    var stringTrees = [String:StringTree]()
//
//    var stringTree : StringTree?
//    {
//        get {
//            guard let activeWordsString = activeWordsString else {
//                return nil
//            }
//
//            if stringTrees[activeWordsString] == nil {
//                stringTrees[activeWordsString] = StringTree(lexicon:lexicon, stringsFunction: { [weak self] in
//                    return self?.lexicon?.stringsFunction?()
//                }, incremental:true)
//            }
//
//            return stringTrees[activeWordsString]
//        }
//        set {
//            guard let activeWordsString = activeWordsString else {
//                return
//            }
//
//            stringTrees[activeWordsString] = newValue
//        }
//    }
    
    var searchText:String?
    {
        get {
            return lexicon?.selected
        }
        set {
            lexicon?.selected = newValue

            wordsTableViewController.selectedText = searchText
            
            Thread.onMainThread {
                self.updateSelectedWord()
                self.updateLocateButton()
            }
            
            updateSearchResults()
        }
    }
    
    var results:MediaListGroupSort?

    var changesPending = false

    var selectedMediaItem:MediaItem?
    
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(LexiconIndexViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "LexiconIndexViewController")
        }
    }
    
    @IBOutlet weak var container: UIView!
    
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var selectedWord: UILabel!
    
    @IBOutlet weak var locateButton: UIButton!
    @IBAction func LocateAction(_ sender: UIButton)
    {
        wordsTableViewController.selectString(searchText,scroll: true,select: true)
    }
    
    func updateDirectionLabel()
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
    
    func updateSearchResults()
    {
        guard let searchText = searchText else {
            results = nil
            Thread.onMainThreadSync { [weak self] in
                self?.tableView.reloadData()
                self?.updateUI()
            }
            return
        }

        // Show the results directly rather than by executing a search
        results = MediaListGroupSort(mediaItems: self.lexicon?.words?[searchText]?.map({ (mediaItemFrequency:(key:MediaItem,value:Int)) -> MediaItem in
            return mediaItemFrequency.key
        }))
        
        Thread.onMainThreadSync { [weak self] in
            if self?.tableView.isEditing == false {
                self?.tableView.reloadData()
            } else {
                self?.changesPending = true
            }
            
            self?.updateUI()
        }
    }
    
    @objc var wordsTableViewController:PopoverTableViewController!
    
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
            case Constants.SEGUE.SHOW_WORD_LIST:
                if let destination = dvc as? PopoverTableViewController {
                    wordsTableViewController = destination
                    
//                    wordsTableViewController.section.useInsertions = true
                    wordsTableViewController.segments = true
                    
                    wordsTableViewController.section.cancelSearchfunction = { [weak self] (method:String?,strings:[String]?) -> [String]? in
                        return self?.wordsTableViewController.section.function?(method,
                            strings?.compactMap({ (string:String) -> String? in
                                return string.components(separatedBy: Constants.SINGLE_SPACE).first
                            })
                        )
                    }
                    
                    // This is not just strings.sort(method) because we have to pull from the lexicon in real time as it is being updated.
                    // If we knew the lexicon was complete we could use the much simpler strings.sort(method) as mediaItem words AlertAction does.
                    wordsTableViewController.section.function = { [weak self] (method:String?,strings:[String]?) -> [String]? in
                        guard let strings = strings else {
                            return nil
                        }
                        
                        guard let method = method else {
                            return nil
                        }
                            
                        var occurrences = [String:Int]()
                        
                        strings.forEach({ (string:String) in
                            occurrences[string] = self?.lexicon?.occurrences(string) // .components(separatedBy: Constants.SINGLE_SPACE).first
                        })
                        
                        var sortedStrings:[String]? = nil
                        
                        switch method {
                        case Constants.Sort.Length:
                            sortedStrings = strings.sorted(by: { (first:String, second:String) -> Bool in
                                guard let firstCount = first.components(separatedBy: Constants.SINGLE_SPACE).first?.count else {
                                    return false
                                }
                                
                                guard let secondCount = second.components(separatedBy: Constants.SINGLE_SPACE).first?.count else {
                                    return true
                                }
                                
                                if firstCount == secondCount {
                                    return first < second
                                } else {
                                    return firstCount > secondCount
                                }
                            })

                        case Constants.Sort.Alphabetical:
                            sortedStrings = strings.sorted()
                            
                        case Constants.Sort.Frequency:
                            sortedStrings = strings.sorted(by: { (first:String, second:String) -> Bool in
                                guard occurrences[first] != occurrences[second] else {
                                    return first < second
                                }
                                return occurrences[first] > occurrences[second]
                            })
//                            .map({ (string:String) -> String in
//                                if let count = occurrences[string] {
//                                    return string + " (\(count))"
//                                } else {
//                                    return string
//                                }
//                            })
                            
                        default:
                            break
                        }
                    
                        return sortedStrings?.map({ (string:String) -> String in
                            if let count = occurrences[string] {
                                return string + " (\(count))"
                            } else {
                                return string
                            }
                        })
                    }
                        
                    wordsTableViewController.section.method = Constants.Sort.Alphabetical
                    
//                    wordsTableViewController.bottomBarButton = true
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
//                        DispatchQueue.global(qos: .background).async { [weak self] in
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMainThread {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
//                            self?.wordsTableViewController.section.sorting = true
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Alphabetical,self?.lexicon?.words?.keys()) // self?.wordsTableViewController.section.strings

                            Thread.onMainThread {
                                guard let wordsTableViewController = self?.wordsTableViewController else {
                                    return
                                }
                                
                                guard let section = wordsTableViewController.section else {
                                    return
                                }
                                
                                if wordsTableViewController.segmentedControl.selectedSegmentIndex == 0 {
                                    section.method = Constants.Sort.Alphabetical
                                    
                                    section.showHeaders = false
                                    section.showIndex = true
                                    
                                    section.indexStringsTransform = nil
                                    section.indexHeadersTransform = nil
                                    
                                    section.indexSort = nil
                                }
                                
                                wordsTableViewController.unfilteredSection.sorting = true
                                wordsTableViewController.unfilteredSection.strings = strings
                                wordsTableViewController.unfilteredSection.sorting = false

                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.creating == false {
                                    self?.wordsTableViewController.activityIndicator.stopAnimating()
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true
//                                section.sorting = false

                                self?.updateLocateButton()
                            }
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        //                        DispatchQueue.global(qos: .background).async { [weak self] in
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMainThread {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
                            //                            self?.wordsTableViewController.section.sorting = true
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Frequency,self?.lexicon?.words?.keys()) // self?.wordsTableViewController.section.strings
                            
                            Thread.onMainThread {
                                guard let wordsTableViewController = self?.wordsTableViewController else {
                                    return
                                }
                                
                                guard let section = wordsTableViewController.section else {
                                    return
                                }
                                
                                if wordsTableViewController.segmentedControl.selectedSegmentIndex == 1 {
                                    section.method = Constants.Sort.Frequency
                                    
                                    section.showHeaders = false
                                    section.showIndex = true
                                    
                                    section.indexStringsTransform = { (string:String?) -> String? in
                                        return string?.log
                                    }
                                    
                                    section.indexHeadersTransform = { (string:String?) -> String? in
                                        return string
                                    }
                                    
                                    section.indexSort = { (first:String?,second:String?) -> Bool in
                                        guard let first = first else {
                                            return false
                                        }
                                        guard let second = second else {
                                            return true
                                        }
                                        return Int(first) > Int(second)
                                    }
                                }
                                
                                wordsTableViewController.unfilteredSection.sorting = true
                                wordsTableViewController.unfilteredSection.strings = strings
                                wordsTableViewController.unfilteredSection.sorting = false
                                
                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.creating == false {
                                    wordsTableViewController.activityIndicator.stopAnimating()
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true
                                //                                section.sorting = false
                                
                                self?.updateLocateButton()
                            }
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Length, position: 2, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        //                        DispatchQueue.global(qos: .background).async { [weak self] in
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMainThread {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
                            //                            self?.wordsTableViewController.section.sorting = true
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Length,self?.lexicon?.words?.keys()) // self?.wordsTableViewController.section.strings
                            
                            Thread.onMainThread {
                                guard let wordsTableViewController = self?.wordsTableViewController else {
                                    return
                                }
                                
                                guard let section = wordsTableViewController.section else {
                                    return
                                }
                                
                                if wordsTableViewController.segmentedControl.selectedSegmentIndex == 2 {
                                    section.method = Constants.Sort.Length
                                    
                                    section.showHeaders = false
                                    section.showIndex = true
                                    
                                    section.indexStringsTransform = { (string:String?) -> String? in
                                        return string?.components(separatedBy: Constants.SINGLE_SPACE).first?.count.description
                                    }
                                    
                                    section.indexHeadersTransform = { (string:String?) -> String? in
                                        return string
                                    }
                                    
                                    section.indexSort = { (first:String?,second:String?) -> Bool in
                                        guard let first = first else {
                                            return false
                                        }
                                        guard let second = second else {
                                            return true
                                        }
                                        return Int(first) > Int(second)
                                    }
                                }
                                
                                wordsTableViewController.unfilteredSection.sorting = true
                                wordsTableViewController.unfilteredSection.strings = strings
                                wordsTableViewController.unfilteredSection.sorting = false
                                
                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.creating == false {
                                    wordsTableViewController.activityIndicator.stopAnimating()
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true
                                //                                section.sorting = false
                                
                                self?.updateLocateButton()
                            }
                        }
                    }))
                    
                    wordsTableViewController.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    wordsTableViewController.delegate = self
                    wordsTableViewController.purpose = .selectingLexicon
                    
                    wordsTableViewController.search = true // lexicon?.completed ?? false
                    wordsTableViewController.segments = true

                    wordsTableViewController.section.showIndex = true
                    
                    // Need to use this now that lexicon.strings is a computed variable and for large lexicons it can take a while.
                    wordsTableViewController.stringsFunction = { [weak self] in
//                        return self.mediaListGroupSort?.lexicon?.strings

                        return self?.mediaListGroupSort?.lexicon?.strings?.sorted().map({ (string:String) -> String in
                            if let count = self?.lexicon?.occurrences(string) {
                                return string + " (\(count))"
                            } else {
                                return string
                            }
                        })
                    }
                }
                break
                
            case Constants.SEGUE.SHOW_INDEX_MEDIAITEM:
                if let myCell = sender as? MediaTableViewCell {
                    selectedMediaItem = myCell.mediaItem
                    
                    if selectedMediaItem != nil {
                        if let destination = dvc as? MediaViewController {
                            destination.selectedMediaItem = selectedMediaItem
                        }
                    }
                }
                break
                
            default:
                break
            }
        }
    }
    
    func updateSelectedWord()
    {
        guard let searchText = self.searchText else {
            Thread.onMainThread {
                self.locateView.isHidden = true
                self.selectedWord.text = Constants.EMPTY_STRING
            }
            return
        }
        
        guard let occurrences = lexicon?.occurrences(searchText) else {
            return
        }
        
        guard let documents = lexicon?.documents(searchText) else {
            return
        }
        
        Thread.onMainThread {
            self.locateView.isHidden = false
            self.selectedWord.text = "\(searchText) (\(occurrences) in \(documents))" // searchText
        }
    }

    var sortingObserver = false
    
    func updateLocateButton()
    {
        // Not necessarily called on the main thread.
        
        guard self.searchText != nil else {
            Thread.onMainThread {
                self.locateView.isHidden = true
                self.locateButton.isHidden = true
                self.locateButton.isEnabled = false
            }
            return
        }

        // isEnabled is first set here.
        setTableViewHeightConstraint(change:0)

        Thread.onMainThread {
            self.locateView.isHidden = false
            self.locateButton.isHidden = false
            
            if !self.wordsTableViewController.tableView.isHidden {
                // This creates an ordering dependency, if sorting is true and then becomes false a notification is required or the button will remain disabled.
                // See notification SORTING_CHANGED
                self.locateButton.isEnabled = !self.wordsTableViewController.section.sorting && (self.tableViewHeightConstraint.isActive ? self.locateButton.isEnabled : true)
            } else {
                self.locateButton.isEnabled = false
            }
        }
    }

    @objc func sortingChanged()
    {
        updateLocateButton()
    }
    
    func addNotifications()
    {
        guard lexicon != nil else {
            return
        }

//        Globals.shared.queue.async {
//            NotificationCenter.default.addObserver(self, selector: #selector(self.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
//            NotificationCenter.default.addObserver(self, selector: #selector(self.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
//            NotificationCenter.default.addObserver(self, selector: #selector(self.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
////
////            NotificationCenter.default.addObserver(self, selector: #selector(self.sortingChanged), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SORTING_CHANGED), object: self.wordsTableViewController)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        lexicon?.callBacks.register(id: "LIVC", callBack: CallBack(
            start:{[weak self] in
                self?.started()
            },
            update:{[weak self] in
                self?.updated()
            },
            complete:{[weak self] in
                self?.completed()
            }
            )
        )

        navigationItem.hidesBackButton = false

//        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            // entries property is computationally expensive
//            // eligible property is computationally expensive if not cached in shadow.
//            if let count = self?.lexicon?.entries?.count,
//                let total = self?.lexicon?.eligible?.count {
//                Thread.onMainThread {
//                    self?.navigationItem.title = "Lexicon Index \(count) of \(total)"
//                }
//            }
//        }

        wordsTableViewController.selectedText = searchText
        
        wordsTableViewController.section.stringsAction = { [weak self] (strings:[String]?,sorting:Bool) in
            Thread.onMainThread {
                self?.updateActionMenu()
                self?.wordsTableViewController.segmentedControl.isEnabled = (strings != nil) && (sorting == false)
            }
        }
        
        updateSearchResults()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if lexicon?.completed == false {
            wordsTableViewController.activityIndicator.startAnimating()
            lexicon?.build()
        }
        
        // Necessary to get the token word list to extend fully.
        setTableViewHeightConstraint(change:0)
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

    func setupMediaItemsHTMLLexicon(includeURLs:Bool,includeColumns:Bool) -> String?
    {
        guard let mediaItems = results?.mediaItems else {
            return nil
        }
        
        guard let grouping = Globals.shared.grouping, let sorting = Globals.shared.sorting else {
            return nil
        }
        
        var bodyString = "<!DOCTYPE html><html><body>"
        
        if let searchText = searchText {
            bodyString = bodyString + "Lexicon Index For \(searchText):"
            
            var appearances = 0

            for mediaItem in mediaItems {
                if let count = mediaItem.notesTokens?.result?[searchText] {
                    appearances += count
                }
            }
            
            bodyString = bodyString + " \(appearances) Occurrences in \(mediaItems.count) Documents<br/><br/>"
        }
        
        bodyString = bodyString + "The following media "
        
        if results?.mediaList?.list?.count > 1 {
            bodyString = bodyString + "are"
        } else {
            bodyString = bodyString + "is"
        }
        
        if includeURLs {
            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = Globals.shared.mediaCategory.selected {
            bodyString = bodyString + "Category: \(category)<br/>"
        }
        
        if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
            bodyString = bodyString + "Collection: \(tag)<br/>"
        }
        
        if Globals.shared.search.isValid, let searchText = Globals.shared.search.text {
            bodyString = bodyString + "Search: \(searchText)<br/>"
        }
        
        if let grouping = Globals.shared.grouping?.translate {
            bodyString = bodyString + "Grouped: By \(grouping)<br/>"
        }
        
        if let sorting = Globals.shared.sorting?.translate {
            bodyString = bodyString + "Sorted: \(sorting)<br/>"
        }
        
        if let keys = results?.section?.indexStrings {
            if includeURLs, (keys.count > 1) {
                bodyString = bodyString + "<br/>"
                bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
            }
            
            if includeColumns {
                bodyString = bodyString + "<table>"
            }
            
            for key in keys {
                if  let name = results?.groupNames?[grouping,key], // ]?[
                    let mediaItems = results?.groupSort?[grouping,key,sorting] { // ]?[
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        if let speaker = mediaItem.speaker {
                            guard let count = speakerCounts[speaker] else {
                                speakerCounts[speaker] = 1
                                continue
                            }

                            speakerCounts[speaker] = count + 1
                        }
                    }
                    
                    let speakerCount = speakerCounts.keys.count
                    
                    let tag = key.asTag

                    if includeColumns {
                        bodyString = bodyString + "<tr><td><br/></td></tr>"
                        bodyString = bodyString + "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" // valign=\"baseline\" 
                    }
                    
                    if includeURLs, (keys.count > 1) {
                        bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + " (\(mediaItems.count))" + "</a>"
                    } else {
                        bodyString = bodyString + name + " (\(mediaItems.count))"
                    }
                    
                    if speakerCount == 1 {
                        if let speaker = mediaItems[0].speaker, name != speaker {
                            bodyString = bodyString + " by " + speaker
                        }
                    }
                    
                    if includeColumns {
                        bodyString = bodyString + "</td>"
                        bodyString = bodyString + "</tr>"
                    } else {
                        bodyString = bodyString + "<br/>"
                    }
                    
                    for mediaItem in mediaItems {
                        var order = ["date","title","count","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        if Globals.shared.grouping != GROUPING.CLASS {
                            if mediaItem.hasClassName {
                                order.append("class")
                            }
                        }
                        
                        if Globals.shared.grouping != GROUPING.EVENT {
                            if mediaItem.hasEventName {
                                order.append("event")
                            }
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, token: searchText, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString = bodyString + string
                        }
                        
                        if !includeColumns {
                            bodyString = bodyString + "<br/>"
                        }
                    }
                }
            }
            
            if includeColumns {
                bodyString = bodyString + "</table>"
            }
            
            bodyString = bodyString + "<br/>"
            
            if includeURLs, keys.count > 1 {
                bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
                
                if let grouping = Globals.shared.grouping {
                    switch grouping {
                    case GROUPING.CLASS:
                        fallthrough
                    case GROUPING.SPEAKER:
                        fallthrough
                    case GROUPING.TITLE:
                        let a = "A"
                        
                        if let indexTitles = results?.section?.indexStrings {
                            let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                                if string.count >= a.count { // endIndex
                                    let indexString = String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
                                    
                                    return indexString
                                } else {
                                    return string
                                }
                            }))).sorted() { $0 < $1 }
                            
                            var stringIndex = [String:[String]]()
                            
                            if let indexStrings = results?.section?.indexStrings {
                                for indexString in indexStrings {
                                    let key = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)]).uppercased()
                                    
                                    if stringIndex[key] == nil {
                                        stringIndex[key] = [String]()
                                    }
                                    stringIndex[key]?.append(indexString)
                                }
                            }
                            
                            var index:String?
                            
                            for title in titles {
                                let link = "<a href=\"#\(title)\">\(title)</a>"
                                index = ((index != nil) ? index! + " " : "") + link
                            }
                            
                            bodyString = bodyString + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                            
                            if let index = index {
                                bodyString = bodyString + index + "<br/><br/>"
                            }
                            
                            for title in titles {
                                bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                                
                                if let keys = stringIndex[title] {
                                    for key in keys {
                                        if let title = results?.groupNames?[grouping,key], // ]?[
                                            let count = results?.groupSort?[grouping,key,sorting]?.count { // ]?[
                                            let tag = key.asTag
                                            bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                                        }
                                    }
                                    bodyString = bodyString + "<br/>"
                                }
                            }
                            
                            bodyString = bodyString + "</div>"
                        }
                        break
                        
                    default:
                        for key in keys {
                            if let title = results?.groupNames?[grouping,key], // ]?[
                                let count = results?.groupSort?[grouping,key,sorting]?.count { // ]?[
                                let tag = key.asTag
                                bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                            }
                        }
                        break
                    }
                }
                
                bodyString = bodyString + "</div>"
            }
        }
        
        bodyString = bodyString + "</body></html>"
        
        return bodyString.insertHead(fontSize:Constants.FONT_SIZE)
    }
    
    var activeWords : [String]?
    {
        get {
            return lexicon?.activeWords(wordsTableViewController.searchText)
            
//            guard let searchText = wordsTableViewController.searchText else {
//                return lexicon?.words?.keys()?.sorted()
//            }
//
//            return lexicon?.words?.keys()?.filter({ (string:String) -> Bool in
//                return string.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
//            }).sorted()

//            return wordsTableViewController.section.strings?.compactMap({ (string:String) -> String? in
//                if let range = string.range(of: " (") {
//                    return String(string[..<range.lowerBound])
//                } else {
//                    return nil
//                }
//            })
        }
    }

    var activeWordsString : String?
    {
        get {
            return lexicon?.activeWordsString(wordsTableViewController.searchText)
//            return activeWords?.sorted().joined()
        }
    }
    
    var activeWordsHTML : String?
    {
        get{
            return lexicon?.activeWordsHTML(wordsTableViewController.searchText)
//
//            var bodyHTML:String! = "<!DOCTYPE html>" //setupMediaItemsHTML(self?.mediaListGroupSort?.mediaItems, includeURLs: true, includeColumns: true)?.replacingOccurrences(of: "</body></html>", with: "") //
//
//            bodyHTML += "<html><body>"
//
//            var wordsHTML = ""
//            var indexHTML = ""
//
//            if let words = activeWords?.sorted(by: { (lhs:String, rhs:String) -> Bool in
//                return lhs < rhs
//            }) {
//                var roots = [String:Int]()
//
//                var keys : [String] {
//                    get {
//                        return roots.keys.sorted()
//                    }
//                }
//
//                words.forEach({ (word:String) in
//                    let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                    //                    let key = String(word[..<String.Index(encodedOffset: 1)])
//                    if let count = roots[key] {
//                        roots[key] = count + 1
//                    } else {
//                        roots[key] = 1
//                    }
//                })
//
//                bodyHTML += "<br/>"
//
//                //                    bodyHTML += "<p>Index to \(words.count) Words</p>"
//                bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
//
//                if let searchText = wordsTableViewController.searchText?.uppercased() {
//                    bodyHTML += "Search Text: \(searchText)<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
//                }
//
//                //                    indexHTML = "<table>"
//                //
//                //                    indexHTML += "<tr>"
//
//                var index : String?
//
//                for root in roots.keys.sorted() {
//                    let tag = root.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? root
//
//                    let link = "<a id=\"wordIndex\(tag)\" name=\"wordIndex\(tag)\" href=\"#words\(tag)\">\(root)</a>"
//                    index = ((index != nil) ? index! + " " : "") + link
//                }
//
//                indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
//
//                if let index = index {
//                    indexHTML += index + "<br/>"
//                }
//
//                //                    indexHTML = indexHTML + "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a></div>"
//                //                    for root in roots.keys.sorted() {
//                //                        indexHTML += "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=#words\(root)>" + root + "</a>" // "<td>" + + "</td>"
//                //                    }
//
//                //                    indexHTML += "</tr>"
//                //
//                //                    indexHTML += "</table>"
//
//                indexHTML += "<br/>"
//
//                wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
//
//                wordsHTML += "<div class=\"index\">"
//
//                wordsHTML += "<ul class=\"words\">"
//
//                //                    wordsHTML += "<tr><td></td></tr>"
//
//                //                    indexHTML += "<style>.word{ float: left; margin: 5px; padding: 5px; width:300px; } .wrap{ width:1000px; column-count: 3; column-gap:20px; }</style>"
//
//                var section = 0
//
//                //                    wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
//
//                let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
//
//                wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
//
//                for word in words {
//                    let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                    //                    let first = String(word[..<String.Index(encodedOffset: 1)])
//
//                    if first != keys[section] {
//                        // New Section
//                        section += 1
//                        //                            wordsHTML += "<tr><td></td></tr>"
//
//                        //                            wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
//
//                        wordsHTML += "</ul>"
//
//                        wordsHTML += "<br/>"
//
//                        wordsHTML += "<ul class=\"words\">"
//
//                        let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
//
//                        wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
//                    }
//
//                    //                        wordsHTML += "<tr><td>" + word + "</td></tr>"
//
//                    //                        wordsHTML += "<li>" + word + "</li>"
//                    wordsHTML += "<li>"
//
//                    if let searchText = wordsTableViewController.searchText {
//                        wordsHTML += word.markSearchHTML(searchText)
//                    } else {
//                        wordsHTML += word
//                    }
//
//                    // Word Frequency and Links Back to Documents
//                    //                        if let entries = words?[word]?.sorted(by: { (first:(key: MediaItem, value: Int), second:(key: MediaItem, value: Int)) -> Bool in
//                    //                            first.key.title?.withoutPrefixes < second.key.title?.withoutPrefixes
//                    //                        }) {
//                    //                            var count = 0
//                    //                            for entry in entries {
//                    //                                count += entry.value
//                    //                            }
//                    //                            wordsHTML += " (\(count))"
//                    //
//                    //                            wordsHTML += "<ul>"
//                    //                            var i = 1
//                    //                            for entry in entries {
//                    //                                if let tag = entry.key.title?.asTag {
//                    //                                    wordsHTML += "<li class\"back\">"
//                    //                                    wordsHTML += "<a href=#\(tag)>\(entry.key.title!)</a> (\(entry.value))"
//                    //                                    wordsHTML += "</li>"
//                    //                                }
//                    //                                i += 1
//                    //                            }
//                    //                            wordsHTML += "</ul>"
//                    //                        }
//
//                    wordsHTML += "</li>"
//                }
//
//                wordsHTML += "</ul>"
//
//                wordsHTML += "</div>"
//
//                wordsHTML += "</div>"
//            }
//
//            bodyHTML += indexHTML + wordsHTML + "</body></html>"
//
//            return bodyHTML
        }
    }

    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()

        if activeWords?.count > 0 {
            actionMenu.append(Constants.Strings.Word_Picker)
            actionMenu.append(Constants.Strings.Word_List)
        }

        if results?.mediaList?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }

        if lexicon?.completed == false {
            actionMenu.append("Stop")
        }

        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:actions", completion: nil)
            return
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationItem.title = "Select"
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenuItems()

            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateTitle()
    {
        Thread.onMainThreadSync {
            if  let count = self.lexicon?.entries?.count,
                let total = self.lexicon?.eligible?.count {
                self.navigationItem.title = "Lexicon Index \(count) of \(total)"
            }
        }
    }
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "LIVC" // Asumes there is only ever one at a time globally.
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    
        lexicon?.callBacks.unregister(id: "LIVC")
    }
    
    @objc func started()
    {
        
    }
    
    @objc func updated()
    {
        guard !self.wordsTableViewController.section.sorting else {
            return
        }
        
        let op = CancelableOperation { [weak self] (test:(() -> Bool)?) in
            Thread.onMainThreadSync {
                self?.wordsTableViewController.segmentedControl.isEnabled = false
                //                self.wordsTableViewController.tableView.isHidden = true // Turned out getting rid of this was the big innovation, NOT insertions!
            }
            
            if test?() == true {
                return
            }
            
            self?.wordsTableViewController.unfilteredSection.sorting = self?.wordsTableViewController.section.function != nil
            self?.wordsTableViewController.unfilteredSection.strings = (self?.wordsTableViewController.section.function == nil) ? self?.lexicon?.strings : self?.wordsTableViewController.section.function?(self?.wordsTableViewController.section.method, self?.lexicon?.strings)
            self?.wordsTableViewController.unfilteredSection.sorting = false

            if test?() == true {
                return
            }
            
            Thread.onMainThreadSync {
                self?.wordsTableViewController.tableView.reloadData()
                //                self.wordsTableViewController.tableView.isHidden = false // Turned out getting rid of this was the big innovation, NOT insertions!
            }
            
            if test?() == true {
                return
            }
            
            self?.wordsTableViewController.updateSearchResults()

            if test?() == true {
                return
            }

            self?.updateSearchResults()

            Thread.onMainThreadSync {
                self?.wordsTableViewController.segmentedControl.isEnabled = true
            }
        }
        operationQueue.addOperation(op)
        
//        operationQueue.addOperation { [weak self] in
            // Need to block while waiting for the tableView to be hidden.
//            Thread.onMainThreadSync {
//                self.wordsTableViewController.segmentedControl.isEnabled = false
////                self.wordsTableViewController.tableView.isHidden = true
//            }
//
//            self.wordsTableViewController.section.sorting = self.wordsTableViewController.section.function != nil
//
//            self.wordsTableViewController.unfilteredSection.strings = (self.wordsTableViewController.section.function == nil) ? self.lexicon?.strings : self.wordsTableViewController.section.function?(self.wordsTableViewController.section.method,self.lexicon?.strings)
//
//            self.wordsTableViewController.updateSearchResults()
//
//            Thread.onMainThreadSync {
//                self.wordsTableViewController.tableView.reloadData()
////                self.wordsTableViewController.tableView.isHidden = false
//            }
//
//            self.updateSearchResults()
//
//            Thread.onMainThreadSync {
//                self.wordsTableViewController.segmentedControl.isEnabled = true
//
//                self.wordsTableViewController.section.sorting = false
//            }
        
            // Why?
//            if self.operationQueue.operationCount > 1 {
//                Thread.sleep(forTimeInterval: 5) // Does this block since maxConcurrent is 1?
//            }
//        }
    }
    
    @objc func completed()
    {
//        if self.operationQueue.operationCount > 0 {
//            operationQueue.cancelAllOperations()
////            operationQueue.waitUntilAllOperationsAreFinished()
//        }
        
        updated()
        
        operationQueue.addOperation {
            Thread.onMainThreadSync {
                self.wordsTableViewController.activityIndicator.stopAnimating()
            }
        }
    }
    
    @objc func index(_ object:AnyObject?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:index", completion: nil)
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
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
            
            popover.section.strings = results?.section?.headerStrings
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationController?.toolbar.isTranslucent = false
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        navigationItem.setRightBarButton(actionButton, animated: true)
    }
    
    func updateText()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:updateText", completion: nil)
            return
        }
     
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenUI", completion: nil)
            return
        }
        
        directionLabel.isHidden = state
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
        isHiddenNumberAndTableUI(state)
    }
    
    func isHiddenNumberAndTableUI(_ state:Bool)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenNumberAndTableUI", completion: nil)
            return
        }
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
        tableView.isHidden = state
    }
    
    func updateActionMenu()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:updateActionMenu", completion: nil)
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateToolbar()
    {
        guard tableView.numberOfSections > 1 else {
            if self.navigationController?.visibleViewController == self {
                self.navigationController?.isToolbarHidden = true
            }
            return
        }

        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItem.Style.plain, target: self, action: #selector(index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([spaceButton,indexButton], animated: false)
        
        if self.navigationController?.visibleViewController == self {
            self.navigationController?.isToolbarHidden = false
        }
        
//        if let isToolbarHidden = navigationController?.isToolbarHidden, let height = navigationController?.toolbar.frame.height {
//            let height = self.view.bounds.height + (!isToolbarHidden ? height : 0)
//
//            if navigationController?.visibleViewController == self {
//                self.navigationController?.isToolbarHidden = (height - tableViewHeightConstraint.constant) < tableView.rowHeight
//            }
//        }
    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "LexiconIndexViewController:updateUI", completion: nil)
            return
        }

        updateActionMenu()
        
        isHiddenUI(false)
        
        updateDirectionLabel()
        
        updateTitle()
        
        updateText()
        
        updateToolbar()

        updateSelectedWord()
        
        updateLocateButton()

        setTableViewHeightConstraint(change:0)
        
        if lexicon?.completed == false {
            wordsTableViewController.activityIndicator.startAnimating()
        }

        spinner.isHidden = true
        spinner.stopAnimating()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
        // We should close.
        if navigationController?.visibleViewController == self {
            navigationController?.popToRootViewController(animated: true)
        }
        
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}

extension LexiconIndexViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // WHY IS ALL THIS COMMNTED OUT?  Because segue to MVC adds to history.
//        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
//            return
//        }
        
//        var mediaItem:MediaItem?
//        
//        mediaItem = cell.mediaItem
//        
//        Globals.shared.addToHistory(mediaItem)
    }

    func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath: IndexPath)
    {
        // Tells the delegate that the table view is about to go into editing mode.
        
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMainThread {
                self.tableView.reloadData()
            }
        }
        
        changesPending = false
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        var mediaItem : MediaItem?
        
        if (indexPath.section >= 0) && (indexPath.section < results?.section?.indexes?.count) {
            if let section = results?.section?.indexes?[indexPath.section] {
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.mediaItems?.count {
                    mediaItem = results?.mediaItems?[section + indexPath.row]
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
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: {
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

extension LexiconIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard results?.section?.headerStrings != nil else {
            return nil
        }

        if (section >= 0) && (section < results?.section?.headerStrings?.count) {
            return results?.section?.headerStrings?[section]
        } else {
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        if let count = results?.section?.counts?.count {
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let count = results?.section?.counts?[section] {
            return count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as? MediaTableViewCell) ?? MediaTableViewCell()

        cell.hideUI()
        
        cell.vc = self
        
        cell.searchText = searchText
        
        if (indexPath.section >= 0) && (indexPath.section < results?.section?.indexes?.count) {
            if let section = results?.section?.indexes?[indexPath.section] {
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.mediaItems?.count {
                    cell.mediaItem = results?.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section >= 0, section < results?.section?.headerStrings?.count, let title = results?.section?.headerStrings?[section] else {
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
            header.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            header.textLabel?.text = nil
            header.textLabel?.textColor = UIColor.black
            
            header.alpha = 0.85
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var view : LexiconIndexViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "LexiconIndexViewController") as? LexiconIndexViewControllerHeaderView
        
        if view == nil {
            view = LexiconIndexViewControllerHeaderView()
        }
        
        view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        
        if view?.label == nil {
            let label = UILabel()
            
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(label)

//            if let superview = label.superview {
//                let centerY = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
//                label.superview?.addConstraint(centerY)
//
//                let leftMargin = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.leftMargin, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.leftMargin, multiplier: 1.0, constant: 0.0)
//                label.superview?.addConstraint(leftMargin)
//            }
            
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllLeft], metrics: nil, views: ["label":label]))
            
            view?.label = label
        }
        
        view?.alpha = 0.85
        
        if section >= 0, section < results?.section?.headerStrings?.count, let title = results?.section?.headerStrings?[section] {
            view?.label?.attributedText = NSAttributedString(string: title, attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR", attributes: Constants.Fonts.Attributes.bold)
        }
        
        return view
    }
}
