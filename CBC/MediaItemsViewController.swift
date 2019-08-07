//
//  MediaItemsViewController.swift
//  CBC
//
//  Created by Steve Leeke on 5/20/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

/**

 Abstract class for a view controller that has a list of mediaItems
 
 Concrete subclasses: MediaTableViewController, MediaViewController, LexiconIndexViewController, ScriptureIndexViewController

 Properties: (other than those required by protocols)
    - None
 
 Protocols:
    - PopoverTableViewControllerDelegate
 
 */

class LabelHeaderFooterView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class MediaItemsViewController : CBCViewController, PopoverTableViewControllerDelegate
{
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()
    
    // Do nothing
    func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return nil
    }
    
    func rowAlertActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    @objc func downloadFailed(_ notification:NSNotification)
    {
        
    }
    
    // UITableViewDataSource Protocol - This never gets called.  It must be in subclasses since that is where the LabelHeaderFooterView is registered.
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
//    {
//        if let header = view as? UITableViewHeaderFooterView {
//            header.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
//            
//            header.textLabel?.text = nil
//            header.textLabel?.textColor = UIColor.black
//            
//            header.alpha = 0.85
//        }
//    }
    //////////////////////////////
    
    // UITableViewDelegate Protocol - Never gets called, must be in the subclass.
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
//    {
//        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
//            let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
//                guard var alertActions = cell.mediaItem?.editActions(viewController: self) else {
//                    return
//                }
//                
//                alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil))
//                Alerts.shared.alert(title: Constants.Strings.Actions, message: message, actions: alertActions)
//            }
//            action.backgroundColor = UIColor.controlBlue()
//            
//            return [action]
//        }
//        
//        return nil
//    }
    //////////////////////////////
    
    // Handles only the selectingTimingIndex and selectingTime row actions.
    // selectingTimingIndex has four variants: Word, Phrase, Topic, and Keyword
    // While all are implemented only the Word variant is used in the app because
    // it is the useful one and the others really aren't that useful.  They are
    // also problematic in that they use lemmas or other word variants that may
    // not actually appear in the words of the transcript, making it very hard
    // to property find and highlight them in segments or the transcript
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewController:rowClickedAtIndex", completion: nil)
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
//        case .selectingCellAction:
//            popover?.values.forEach({ (popover:PopoverTableViewController) in
//                popover.dismiss(animated: true, completion: nil)
//            })
//
//            switch string {
//            case Constants.Strings.Download_Audio:
//                mediaItem?.audioDownload?.download(background: true)
//                Thread.onMain { [weak self] in 
//                    NotificationCenter.default.addObserver(self, selector: #selector(self?.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
//                }
//                break
//
//            case Constants.Strings.Delete_Audio_Download:
//                mediaItem?.audioDownload?.delete(block:true)
//                break
//
//            case Constants.Strings.Cancel_Audio_Download:
//                mediaItem?.audioDownload?.cancelOrDelete()
//                break
//
//            default:
//                break
//            }
//            break
            
        case .selectingTimingIndexWord:
            guard let searchText = string.components(separatedBy: Constants.SINGLE_SPACE).first else {
                return
            }
            
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self // as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?["TIMINGINDEXWORD"]?.selectedMediaItem
                popover.transcript = self.popover?["TIMINGINDEXWORD"]?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { [weak self] (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = searchText
                popover.wholeWordsOnly = true
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                    return string?.century
                } // century
                popover.section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = { [weak popover] in
                    guard let transcriptSegmentComponents = popover?.transcript?.transcriptSegmentComponents?.result else {
                        return nil
                    }
                    
                    var wordTimes = [String]()

                    if let words = popover?.transcript?.words?.filter({ (dict:[String:Any]) -> Bool in
                        return dict["w"] != nil
                    }) {
                        for i in 0..<words.count {
                            if  let position = words[i]["p"] as? Int,
                                let start = words[i]["s"] as? Int,
                                let end = words[i]["e"] as? Int,
                                let word = words[i]["w"] as? String,
                                let startHMS = (Double(start)/1000.0).secondsToHMSms,
                                let endHMS = (Double(end)/1000.0).secondsToHMSms {
                                if word.lowercased() == searchText.lowercased() {
                                    let midPoint = Double(start+end)/2000.0
                                    if let wordTime = midPoint.secondsToHMSms, !wordTime.isEmpty {
                                        wordTimes.append(wordTime)
                                    }
                                }
                            }
                        }
                    }

                    var strings = [String]()
                    
                    for transcriptSegmentComponent in transcriptSegmentComponents {
                        if transcriptSegmentComponent.contains(" --> ") { //
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
//                                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
//
//                                    let range = NSRange(location: 0, length: text.utf16.count)
//
//                                    if let regex = try? NSRegularExpression(pattern: "\\b" + searchText + "\\b", options: .caseInsensitive) {
//                                        let matches = regex.matches(in: text, options: .withTransparentBounds, range: range)
//
//                                        if matches.count > 0 {
//                                            let string = "\(count)\n\(start) to \(end)\n" + text
//
//                                            if !strings.contains(string) {
//                                                strings.append(string)
//                                            }
//                                        }
//                                    }
                                    
                                    while start.hmsToSeconds <= wordTimes.first?.hmsToSeconds, wordTimes.first?.hmsToSeconds <= end.hmsToSeconds {
                                        let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")

                                        let string = "\(count)\n\(start) to \(end)\n" + text

                                        if !strings.contains(string) {
                                            strings.append(string)
                                        }

                                        wordTimes.removeFirst()
                                    }
                                }
                            }
                        }
                    }

                    return strings.count > 0 ? strings : nil
                    
//                    guard let times = popover?.transcript?.transcriptSegmentTokensTimes?.result?[searchText] else {
//                        return nil
//                    }
//
//                    var strings = [String]()
//
//
//                    for time in times {
//                        for transcriptSegmentComponent in transcriptSegmentComponents {
//                            if transcriptSegmentComponent.contains(time+" --> ") { //
//                                var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
//
//                                if transcriptSegmentArray.count > 2  {
//                                    let count = transcriptSegmentArray.removeFirst()
//                                    let timeWindow = transcriptSegmentArray.removeFirst()
//                                    let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
//
//                                    if  let start = times.first,
//                                        let end = times.last,
//                                        let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
//                                        let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
//                                        let string = "\(count)\n\(start) to \(end)\n" + text
//
//                                        strings.append(string)
//                                    }
//                                }
//                                break
//                            }
//                        }
//                    }
//
//                    return strings
                }
                
                self.popover?["TIMINGINDEXWORD"]?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        // Not used
        case .selectingTimingIndexPhrase:
            guard let searchText = string.word else {
                return
            }
            
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self // as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?["TIMINGINDEXPHRASE"]?.selectedMediaItem
                popover.transcript = self.popover?["TIMINGINDEXPHRASE"]?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { [weak self] (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = searchText
                //                popover.wholeWordsOnly = true // Phrase analysis does not always return a phrase that ends on a word boundary, e.g. "romans chapter" includes "romans chapters"
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                    return string?.century
                } // century
                popover.section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = { [weak popover] in
                    guard let transcriptSegmentComponents = popover?.transcript?.transcriptSegmentComponents?.result else { // (token: string)
                        return nil
                    }
                    
                    guard let times = popover?.transcript?.keywordTimes?[searchText] else { // (token: string)
                        return nil
                    }
                    
                    var strings = [String]()
                    
                    // This guarantees we go through all transcriptSegmentComponents times.count times
                    // Shouldn't we got through transcriptSegmentComponents ONCE and look for times in each one?
                    // (sincd #times << #transcriptSegmentComponents
                    // That would mean a very different algorithm
                    for time in times {
                        var found = false
                        var gap : Double?
                        var closest : String?
                        
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                    let string = "\(count)\n\(start) to \(end)\n" + text
                                    
                                    if (start.hmsToSeconds <= time.hmsToSeconds) && (time.hmsToSeconds <= end.hmsToSeconds) {
                                        strings.append(string)
                                        found = true
                                        gap = nil
                                        break
                                    } else {
                                        guard let time = time.hmsToSeconds else {
                                            continue
                                        }
                                        
                                        guard let start = start.hmsToSeconds else {
                                            continue
                                        }
                                        
                                        guard let end = end.hmsToSeconds else { //
                                            continue
                                        }
                                        
                                        var currentGap = 0.0
                                        
                                        if time < start {
                                            currentGap = start - time
                                        }
                                        if time > end {
                                            currentGap = time - end
                                        }
                                        
                                        if gap != nil {
                                            if currentGap < gap {
                                                gap = currentGap
                                                closest = string
                                            }
                                        } else {
                                            gap = currentGap
                                            closest = string
                                        }
                                    }
                                }
                            }
                        }
                        
                        // We have to deal w/ the case where the keyword time isn't found in a segment which is probably due to a rounding error in the milliseconds, e.g. 1.
                        if !found {
                            if let closest = closest {
                                strings.append(closest)
                            } else {
                                // ??
                            }
                        }
                    }
                    
                    return strings
                }
                                
                self.popover?["TIMINGINDEXPHRASE"]?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        // Not used
        case .selectingTimingIndexTopic:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self // as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?["TIMINGINDEXTOPIC"]?.selectedMediaItem
                popover.transcript = self.popover?["TIMINGINDEXTOPIC"]?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTimingIndexTopicKeyword
                
                popover.section.strings = popover.transcript?.topicKeywords(topic: string)
                
                self.popover?["TIMINGINDEXTOPIC"]?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        // Not used
        case .selectingTimingIndexTopicKeyword:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self // as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?["TIMINGINDEXKEYWORD"]?.selectedMediaItem
                popover.transcript = self.popover?["TIMINGINDEXKEYWORD"]?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { [weak self] (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                if let topic = self.popover?["TIMINGINDEXKEYWORD"]?.navigationController?.visibleViewController?.navigationItem.title {
                    popover.section.strings = popover.transcript?.topicKeywordTimes(topic: topic, keyword: string)?.map({ (string:String) -> String in
                        return string.secondsToHMS ?? "ERROR"
                    })
                }
                
                self.popover?["TIMINGINDEXKEYWORD"]?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        // Used
        case .selectingTime:
            guard Globals.shared.mediaPlayer.currentTime != nil else {
                break
            }
            
            if let time = string.components(separatedBy: "\n")[1].components(separatedBy: " to ").first, !time.isEmpty, let seconds = time.hmsToSeconds {
                Globals.shared.mediaPlayer.seek(to: seconds)
            }
            break
            
        default:
            break
        }
    }
}


