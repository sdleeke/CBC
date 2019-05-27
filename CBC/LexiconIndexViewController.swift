//
//  LexiconIndexViewController.swift
//  CBC
//
//  Created by Steve Leeke on 2/2/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

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

extension LexiconIndexViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

class LexiconIndexViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

/**
 For displaying a lexicon
 */
class LexiconIndexViewController : MediaItemsViewController
{
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setTableViewHeightConstraint(change:0)
            self.updateLocateButton()
        }
    }
    
    func setTableViewHeightConstraint(change:CGFloat)
    {
        guard tableViewHeightConstraint.isActive else {
            return
        }
        
        let oldConstant:CGFloat = tableViewHeightConstraint.constant
        
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
        
        var height = tableView(tableView,viewForHeaderInSection:0)?.bounds.height ?? 0
        
        if height == 0 { // TOTAL HACK
            let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
            let boundingRect = "TITLE".boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil)
            height = boundingRect.height + 26 // MAGIC NUMBER 
        }
        
        let resultsMinimum = searchText != nil ? (tableView.rowHeight + height) : 0
        
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

        if constant != oldConstant {
            // If the change is non-zero we need to update the locate button and save the constraint height.
            updateLocateButton()
            UserDefaults.standard.set(constant, forKey: "LEXICON INDEX RESULTS TABLE VIEW HEIGHT")
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
                return self?.lexicon?.activeWords(searchText:self?.wordsTableViewController.searchText)
            }
            lexicon?.stringTreeFunction = { [weak self] in
                return self?.lexicon?.stringTree(self?.wordsTableViewController.searchText)
            }
        }
    }
    
    private var lexicon:Lexicon?
    {
        get {
            return mediaListGroupSort?.lexicon
        }
    }
    
    var searchText:String?
    {
        get {
            return lexicon?.selected
        }
        set {
            lexicon?.selected = newValue

            wordsTableViewController.selectedText = searchText
            
            updateSearchResults()
        }
    }
    
    var results:MediaListGroupSort?
    {
        didSet {
            
        }
    }
    
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
            Thread.onMainSync { [weak self] in
                self?.tableView.reloadData()
                self?.updateUI()
            }
            return
        }

        // Show the results directly rather than by executing a search
        results = MediaListGroupSort(mediaItems: self.lexicon?.words?[searchText]?.map({ (mediaItemFrequency:(key:MediaItem,value:Int)) -> MediaItem in
            return mediaItemFrequency.key
        }))
        
        Thread.onMainSync { [weak self] in
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
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMain {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Alphabetical,self?.lexicon?.words?.keys())
                            
                            Thread.onMain {
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
                                
                                wordsTableViewController.unfilteredSection.strings = strings

                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.completed == true {
                                    // Need to throw this on the opQueue so it doesn't happen before
                                    // the one in completed()
                                    self?.operationQueue.addOperation {
                                        Thread.onMain {
                                            wordsTableViewController.activityIndicator.stopAnimating()
                                        }
                                    }
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true

                                self?.updateLocateButton()
                            }
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMain {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Frequency,self?.lexicon?.words?.keys())
                            
                            Thread.onMain {
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

                                wordsTableViewController.unfilteredSection.strings = strings
                                
                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.completed == true {
                                    // Need to throw this on the opQueue so it doesn't happen before
                                    // the one in completed()
                                    self?.operationQueue.addOperation {
                                        Thread.onMain {
                                            wordsTableViewController.activityIndicator.stopAnimating()
                                        }
                                    }
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true
                                
                                self?.updateLocateButton()
                            }
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Length, position: 2, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMain {
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                                
                                self?.updateLocateButton()
                            }
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Length,self?.lexicon?.words?.keys())
                            
                            Thread.onMain {
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

                                wordsTableViewController.unfilteredSection.strings = strings
                                
                                wordsTableViewController.updateSearchResults()
                                
                                section.stringsAction?(strings,section.sorting)
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.tableView.reloadData()
                                
                                if self?.lexicon?.completed == true {
                                    // Need to throw this on the opQueue so it doesn't happen before
                                    // the one in completed()
                                    self?.operationQueue.addOperation {
                                        Thread.onMain {
                                            wordsTableViewController.activityIndicator.stopAnimating()
                                        }
                                    }
                                }
                                
                                wordsTableViewController.segmentedControl.isEnabled = true
                                
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
            Thread.onMain {
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
        
        Thread.onMain {
            self.locateView.isHidden = false
            self.selectedWord.text = "\(searchText) (\(occurrences) in \(documents))" // searchText
        }
    }

    var sortingObserver = false
    
    func updateLocateButton()
    {
        // Not necessarily called on the main thread.

        // isEnabled is first set here.
        setTableViewHeightConstraint(change:0)

        guard self.searchText != nil else {
            Thread.onMain {
                self.locateView.isHidden = true
                self.locateButton.isHidden = true
                self.locateButton.isEnabled = false
            }
            return
        }

        Thread.onMain {
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

    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        lexicon?.callBacks.register("LIVC",
            ["start":{[weak self] in
                self?.started()
            },
            "update":{[weak self] in
                self?.updated()
            },
            "complete":{[weak self] in
                self?.completed()
            }]
        )

        navigationItem.hidesBackButton = false

//        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            // entries property is computationally expensive
//            // eligible property is computationally expensive if not cached in shadow.
//            if let count = self?.lexicon?.entries?.count,
//                let total = self?.lexicon?.eligible?.count {
//                Thread.onMain {
//                    self?.navigationItem.title = "Lexicon Index \(count) of \(total)"
//                }
//            }
//        }

        wordsTableViewController.selectedText = searchText
        
        wordsTableViewController.section.stringsAction = { [weak self] (strings:[String]?,sorting:Bool) in
            Thread.onMain {
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

    func setupMediaItemsHTMLLexicon(includeURLs:Bool,includeColumns:Bool, test:(()->(Bool))? = nil) -> String?
    {
        guard let mediaItems = results?.section?.mediaItems else {
            return nil
        }
        
        // Globals.shared
        guard let grouping = mediaListGroupSort?.grouping.value, let sorting = mediaListGroupSort?.sorting.value else {
            return nil
        }
        
        guard test?() != true else {
            return nil
        }
        
        var bodyString = "<!DOCTYPE html><html><body>"
        
        if let searchText = searchText {
            bodyString += "Lexicon Index For \(searchText):"
            
            var appearances = 0

            for mediaItem in mediaItems {
                guard test?() != true else {
                    return nil
                }
                
                if let count = mediaItem.notesTokens?.result?[searchText] {
                    appearances += count
                }
            }
            
            bodyString += " \(appearances) Occurrences in \(mediaItems.count) Documents<br/><br/>"
        }
        
        bodyString += "The following media "
        
        if results?.mediaList?.list?.count > 1 {
            bodyString += "are"
        } else {
            bodyString += "is"
        }
        
        if includeURLs {
            bodyString += " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = mediaListGroupSort?.category.value {
            bodyString += "Category: \(category)<br/>"
        }
        
        if let tag = mediaListGroupSort?.tag.value {
            bodyString += "Tag: \(tag)<br/>"
        }
        
        if mediaListGroupSort?.search.value?.isValid == true, let searchText = mediaListGroupSort?.search.value?.text {
            bodyString += "Search: \(searchText)"
        }
        
        if mediaListGroupSort?.search.value?.transcripts == true {
            bodyString += " (including transcripts)"
        }
        
        bodyString += "<br/>"
        
        if let grouping = mediaListGroupSort?.grouping.value?.translate {
            bodyString += "Grouped: By \(grouping)<br/>"
        }
        
        if let sorting = mediaListGroupSort?.sorting.value?.translate {
            bodyString += "Sorted: \(sorting)<br/>"
        }
        
        if let keys = results?.section?.indexStrings {
            if includeURLs, (keys.count > 1) {
                bodyString += "<br/>"
                bodyString += "<a href=\"#index\">Index</a><br/>"
            }
            
            if includeColumns {
                bodyString += "<table>"
            }
            
            for key in keys {
                guard test?() != true else {
                    return nil
                }
                
                if  let name = results?.groupNames?[grouping,key], // ]?[
                    let mediaItems = results?.groupSort?[grouping,key,sorting] { // ]?[
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
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
                        bodyString += "<tr><td><br/></td></tr>"
                        bodyString += "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" // valign=\"baseline\"
                    }
                    
                    if includeURLs, (keys.count > 1) {
                        bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + "</a>"
                    } else {
                        bodyString += name
                    }
                    
                    if speakerCount == 1 {
                        if let speaker = mediaItems[0].speaker, name != speaker {
                            bodyString += " by " + speaker
                        }
                    }
                    
                    if mediaItems.count > 1 {
                        bodyString += " (\(mediaItems.count))"
                    }
                    
                    if includeColumns {
                        bodyString += "</td>"
                        bodyString += "</tr>"
                    } else {
                        bodyString += "<br/>"
                    }
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
                        var order = ["date","title","count","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        // Globals.shared
                        if mediaListGroupSort?.grouping.value != GROUPING.CLASS {
                            if mediaItem.hasClassName {
                                order.append("class")
                            }
                        }
                        
                        // Globals.shared
                        if mediaListGroupSort?.grouping.value != GROUPING.EVENT {
                            if mediaItem.hasEventName {
                                order.append("event")
                            }
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, token: searchText, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString += string
                        }
                        
                        if !includeColumns {
                            bodyString += "<br/>"
                        }
                    }
                }
            }
            
            if includeColumns {
                bodyString += "</table>"
            }
            
            bodyString += "<br/>"
            
            if includeURLs, keys.count > 1 {
                bodyString += "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
                
                if let grouping = mediaListGroupSort?.grouping.value { // Globals.shared
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
                                    guard test?() != true else {
                                        return nil
                                    }
                                    
                                    let key = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)]).uppercased()
                                    
                                    if stringIndex[key] == nil {
                                        stringIndex[key] = [String]()
                                    }
                                    stringIndex[key]?.append(indexString)
                                }
                            }
                            
                            var index:String?
                            
                            for title in titles {
                                guard test?() != true else {
                                    return nil
                                }
                                
                                let link = "<a href=\"#\(title)\">\(title)</a>"
                                index = ((index != nil) ? index! + " " : "") + link
                            }
                            
                            bodyString += "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                            
                            if let index = index {
                                bodyString += index + "<br/><br/>"
                            }
                            
                            for title in titles {
                                guard test?() != true else {
                                    return nil
                                }
                                
                                bodyString += "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                                
                                if let keys = stringIndex[title] {
                                    for key in keys {
                                        if let title = results?.groupNames?[grouping,key], // ]?[
                                            let count = results?.groupSort?[grouping,key,sorting]?.count { // ]?[
                                            let tag = key.asTag
                                            bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a> (\(count))<br/>"
                                        }
                                    }
                                    bodyString += "<br/>"
                                }
                            }
                            
                            bodyString += "</div>"
                        }
                        break
                        
                    default:
                        for key in keys {
                            guard test?() != true else {
                                return nil
                            }
                            
                            if let title = results?.groupNames?[grouping,key], // ]?[
                                let count = results?.groupSort?[grouping,key,sorting]?.count { // ]?[
                                let tag = key.asTag
                                bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a> (\(count))<br/>"
                            }
                        }
                        break
                    }
                }
                
                bodyString += "</div>"
            }
        }
        
        bodyString += "</body></html>"
        
        return bodyString.insertHead(fontSize:Constants.FONT_SIZE)
    }
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()

        if lexicon?.activeWords(searchText:wordsTableViewController.searchText)?.count > 0 {
            actionMenu.append(Constants.Strings.Word_Picker)
            actionMenu.append(Constants.Strings.Word_Index)
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
        Thread.onMainSync {
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
    
        lexicon?.callBacks.unregister("LIVC")
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
            Thread.onMainSync {
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
            
            Thread.onMainSync {
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

            Thread.onMainSync {
                self?.wordsTableViewController.segmentedControl.isEnabled = true
            }
        }
        operationQueue.addOperation(op)
    }
    
    @objc func completed()
    {
        updated()
        
        operationQueue.addOperation {
            Thread.onMainSync {
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
                        navigationController.modalPresentationStyle = .overCurrentContext // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                    }
                } else {
                    navigationController.modalPresentationStyle = .overCurrentContext // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                }
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Strings.Word_Picker
                
                popover.delegate = self
                
                popover.lexicon = self.lexicon
                
                popover.stringsFunction = lexicon?.stringsFunction
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Word_Index:
            self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                return self?.lexicon?.activeWords(searchText:self?.wordsTableViewController.searchText)?.sorted().tableHTML(searchText:self?.wordsTableViewController.searchText, test:test)
                }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                    // preferredModalPresentationStyle(viewController: self)
                    self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: Constants.Strings.Word_Index, htmlString: data as? String)
            })
            break
            
        case "Stop":
            var alertActions = [AlertAction]()
            alertActions.append(AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { () -> (Void) in
                self.lexicon?.stop()
                if self.navigationController?.visibleViewController == self {
                    self.navigationController?.popViewController(animated: true)
                }
                Alerts.shared.alert(title: "Lexicon Build Stopped")
            }))
            alertActions.append(AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: nil))
            Alerts.shared.alert(title: "Confirm Stopping Lexicon Build", actions: alertActions)
            break
            
        case Constants.Strings.View_List:
            self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                if self?.results?.html?.string == nil {
                    self?.results?.html?.string = self?.setupMediaItemsHTMLLexicon(includeURLs:true, includeColumns:true, test:test)
                }
                
                return self?.results?.html?.string
                }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                    if let searchText = self?.searchText, let vc = self {
                        vc.presentHTMLModal(mediaItem: nil, style: .overFullScreen, title: "Lexicon Index For: \(searchText)", htmlString: data as? String)
                    }
            })
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
                
                //Can't use this reliably w/ variable row heights.
                if tableView.isValid(indexPath) {
                    tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                }
            }
            break
            
        case .selectingLexicon:
            let text = string.word ?? string
            
            guard searchText != text.uppercased() else {
                searchText = nil
                if let indexPath = wordsTableViewController.tableView.indexPathForSelectedRow {
                    wordsTableViewController.tableView.deselectRow(at: indexPath, animated: true)
                }
                break
            }
            
            searchText = text.uppercased()
            
            Thread.onMain {
                self.tableView.setEditing(false, animated: true)
            }
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
            
        default:
            break
        }
    }
}

extension LexiconIndexViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Segue to MVC adds to history.

    }

    func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath: IndexPath)
    {
        // Tells the delegate that the table view is about to go into editing mode.
        
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMain {
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
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.section?.mediaItems?.count {
                    mediaItem = results?.section?.mediaItems?[section + indexPath.row]
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
                guard var alertActions = cell.mediaItem?.editActions(viewController: self) else {
                    return
                }
                
                alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil))
                Alerts.shared.alert(title: Constants.Strings.Actions, message: message, actions: alertActions)
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
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.section?.mediaItems?.count {
                    cell.mediaItem = results?.section?.mediaItems?[section + indexPath.row]
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
