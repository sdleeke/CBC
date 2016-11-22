//
//  PopoverTableViewController.swift
//  TPS
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String], purpose:PopoverPurpose, mediaItem:MediaItem?)
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

class PopoverTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedMediaItem:MediaItem?
    
    var stringsFunction:((Void)->[String]?)?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var showSectionHeaders:Bool = false
    
    var indexStrings:[String]?
    
    var strings:[String]?
    
//    var transform:((String?)->String?)?
    
    lazy var section:Section! = {
        var section = Section()
        return section
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        if purpose != .selectingHistory {
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        } else {
            tableView.rowHeight = 100
        }

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
        if (strings != nil) {
            var max = 0
            
            if (navigationItem.title != nil) {
                max = navigationItem.title!.characters.count
            }
            
            for string in strings! {
                if string.characters.contains("\n") {
                    var newString = string
                    
                    var strings = [String]()
                    
                    repeat {
                        strings.append(newString.substring(to: newString.range(of: "\n")!.lowerBound))
                        newString = newString.substring(from: newString.range(of: "\n")!.upperBound)
                    } while newString.characters.contains("\n")

                    strings.append(newString)

                    for string in strings {
                        if string.characters.count > max {
                            max = string.characters.count
                        }
                    }
                } else {
                    if string.characters.count > max {
                        max = string.characters.count
                    }
                }
            }
            
    //        NSLog("count: \(CGFloat(strings!.count)) rowHeight: \(tableView.rowHeight) height: \(height)")
            
            var width = CGFloat(max * 12)
            if width < 200 {
                width = 200
            }
            
            var height:CGFloat = 0
            
            if purpose != .selectingHistory {
                height = 45 * CGFloat(strings!.count) //35 tableView.rowHeight was -1 which I don't understand
                if height < 150 {
                    height = 150
                }
            } else {
                height = 100 * CGFloat(strings!.count)
            }
            
            if showSectionHeaders {
                height = 1.5*height
            }
            
            self.preferredContentSize = CGSize(width: width, height: height)
        }
        
//        NSLog("Strings: \(strings)")
//        NSLog("Sections: \(sections)")
//        NSLog("Section Indexes: \(sectionIndexes)")
//        NSLog("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func setupIndex()
    {
        if showIndex && (strings != nil) && (indexStrings != nil) {
            let a = "A"
            
            var indexes = [Int]()
            var counts = [Int]()
            
            section.titles = Array(Set(indexStrings!.map({ (string:String) -> String in
                if string.endIndex >= a.endIndex {
                    return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
                } else {
                    return string
                }
            }))).sorted() { $0 < $1 }
            
            var stringIndex = [String:[String]]()
            
            for indexString in indexStrings! {
                if stringIndex[indexString.substring(to: a.endIndex)] == nil {
                    stringIndex[indexString.substring(to: a.endIndex)] = [String]()
                }
//                print(testString,string)
                stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
//                if let testString = transform != nil ? transform!(string) : string {
//                }
            }
            
            var counter = 0
            
            for key in stringIndex.keys.sorted() {
//                print(stringIndex[key]!)
                indexes.append(counter)
                counts.append(stringIndex[key]!.count)
                counter += stringIndex[key]!.count
            }
            
            //                print(section.titles)
            
//            for sectionTitle in section.titles! {
//                var counter = 0
//                
//                for index in 0..<strings!.count {
//                    let testString = transform != nil ? transform!(strings![index]) : strings![index]
//                    
//                    var string:String?
//                    
//                    if testString!.endIndex >= a.endIndex {
//                        //                            print(stringWithoutPrefixes(testString))
//                        if (indexStrings?[index]) != nil {
//                            string = stringWithoutPrefixes(testString)!.substring(to: a.endIndex)
//                        } else {
//                            string = testString
//                        }
//                    } else {
//                        string = testString
//                    }
//                    
//                    if (sectionTitle == string) {
//                        if (counter == 0) {
//                            indexes.append(index)
//                        }
//                        counter += 1
//                    } else {
//                        print(index,strings![index],sectionTitle,string)
//                    }
//                }
//                
//                counts.append(counter)
//            }
            
//            print(indexStrings)
//            print(section.titles)
//            print(indexes)
//            print(counts)
            
//            for string in indexStrings! {
//                print(string)
//            }

//            for string in section.titles! {
//                if let index = section.titles?.index(of:string) {
//                    print(string,indexes[index],counts[index])
//                }
//            }
            
            section.indexes = indexes.count > 0 ? indexes : nil
            section.counts = counts.count > 0 ? counts : nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if stringsFunction != nil {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.startAnimating()
                    self.activityIndicator?.isHidden = false
                })
                self.strings = self.stringsFunction?()
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator?.isHidden = true
//                    DispatchQueue.global(qos: .background).async {
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            self.view.sizeToFit()
//                        })
//                    }
                })
            }
        } else {
            activityIndicator?.isHidden = false
            activityIndicator?.startAnimating()
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        DispatchQueue.global(qos: .background).async {
            self.setupIndex()
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                if self.stringsFunction == nil {
                    self.activityIndicator?.stopAnimating()
                    self.activityIndicator?.isHidden = true
                }
            })
        }
        
        // The code below scrolls to the currently selected tag (if there is one), but that makes getting to All at the top of the list harder.
        // And since the currently selectd tag (if there is one) is shown in the search bar prompt text, I don't think this is needed.
//        if (purpose == .selectingTags) && (globals.mediaItemTagsSelected != nil) && (globals.mediaItemTagsSelected != Constants.All) {
//            if (strings != nil) && (globals.mediaItemTagsSelected != nil) {
//                if (showSectionHeaders) {
//                    let sectionNumber = section.titles!.indexOf(globals.mediaItemTagsSelected!.substringToIndex("A".endIndex))
//                    var row = section.indexes![sectionNumber!]
//                    for increment in 0..<section.counts![sectionNumber!] {
//                        if globals.mediaItemTagsSelected == strings?[row+increment] {
//                            row = increment
//                            break
//                        }
//                    }
//                    let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber!)
//                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
//                } else {
//                    if let row = strings!.indexOf(globals.mediaItemTagsSelected!) {
//                        let indexPath = NSIndexPath(forRow: row, inSection: 0)
//                        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
//                    }
//                }
//            }
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if (showIndex) {
            return self.section.titles != nil ? self.section.titles!.count : 0
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if (showIndex) {
            return self.section.counts != nil ? self.section.counts![section] : 0
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if (showIndex) {
            return self.section.titles
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if (showIndex) {
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (showSectionHeaders) { // showIndex && 
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath)

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingHistory:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingAction:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingCellAction:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingCellSearch:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .showingTags:
            //            NSLog("strings: \(strings[indexPath.row]) mediaItemTag: \(mediaItemSelected?.tags)")
            
            cell.accessoryType = UITableViewCellAccessoryType.none
            
//            if (selectedMediaItem?.tagsArray?.indexOf(strings![index]) != nil) {
//                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
//            } else {
//                cell.accessoryType = UITableViewCellAccessoryType.None
//            }
            break
            
        case .selectingTags:
            //            NSLog("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            let string = strings![index]
            
            switch globals.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case Constants.ALL:
                if ((globals.tags.selected == nil) && (strings![index] == Constants.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingSection:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
            
        case .selectingGrouping:
            if (Constants.groupings[index] == globals.grouping) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == globals.sorting) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingShow:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        
        default:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        }

//        print(strings)
        cell.textLabel?.text = strings![index]

        return cell
    }

    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)

        var index = -1
        if (showIndex) {
            index = self.section.indexes != nil ? self.section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }

        delegate?.rowClickedAtIndex(index, strings: self.strings!, purpose: self.purpose!, mediaItem: self.selectedMediaItem)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
