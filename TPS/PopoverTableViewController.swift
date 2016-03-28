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
    func rowClickedAtIndex(index:Int, strings:[String], purpose:PopoverPurpose, sermon:Sermon?)
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

class PopoverTableViewController: UITableViewController {
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedSermon:Sermon?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var showSectionHeaders:Bool = false
    
    var strings:[String]?
    
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
                        strings.append(newString.substringToIndex(newString.rangeOfString("\n")!.startIndex))
                        newString = newString.substringFromIndex(newString.rangeOfString("\n")!.endIndex)
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
            
    //        print("count: \(CGFloat(strings!.count)) rowHeight: \(tableView.rowHeight) height: \(height)")
            
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
            
            self.preferredContentSize = CGSizeMake(width, height)

            if showIndex {
                let a = "A"
                
                section.titles = Array(Set(strings!.map({ (string:String) -> String in
                    return stringWithoutPrefixes(string)!.substringToIndex(a.endIndex)
                }))).sort() { $0 < $1 }
                
                var indexes = [Int]()
                var counts = [Int]()
                
                for sectionTitle in section.titles! {
                    var counter = 0
                    
                    for index in 0..<strings!.count {
                        if (sectionTitle == stringWithoutPrefixes(strings![index])!.substringToIndex(a.endIndex)) {
                            if (counter == 0) {
                                indexes.append(index)
                            }
                            counter += 1
                        }
                    }
                    
                    counts.append(counter)
                }
                
                section.indexes = indexes.count > 0 ? indexes : nil
                section.counts = counts.count > 0 ? counts : nil
            }
        }
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)

        // The code below scrolls to the currently selected tag (if there is one), but that makes getting to All at the top of the list harder.
        // And since the currently selectd tag (if there is one) is shown in the search bar prompt text, I don't think this is needed.
//        if (purpose == .selectingTags) && (Globals.sermonTagsSelected != nil) && (Globals.sermonTagsSelected != Constants.All) {
//            if (strings != nil) && (Globals.sermonTagsSelected != nil) {
//                if (showSectionHeaders) {
//                    let sectionNumber = section.titles!.indexOf(Globals.sermonTagsSelected!.substringToIndex("A".endIndex))
//                    var row = section.indexes![sectionNumber!]
//                    for increment in 0..<section.counts![sectionNumber!] {
//                        if Globals.sermonTagsSelected == strings?[row+increment] {
//                            row = increment
//                            break
//                        }
//                    }
//                    let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber!)
//                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
//                } else {
//                    if let row = strings!.indexOf(Globals.sermonTagsSelected!) {
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
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if (showIndex) {
            return self.section.titles != nil ? self.section.titles!.count : 0
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if (showIndex) {
            return self.section.counts != nil ? self.section.counts![section] : 0
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if (showIndex) {
            return self.section.titles
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if (showIndex) {
            return index
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (showSectionHeaders) { // showIndex && 
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.POPOVER_CELL_IDENTIFIER, forIndexPath: indexPath)

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section]+indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingHistory:
            cell.accessoryType = UITableViewCellAccessoryType.None
            break
            
        case .selectingAction:
            cell.accessoryType = UITableViewCellAccessoryType.None
            break
            
        case .selectingCellAction:
            cell.accessoryType = UITableViewCellAccessoryType.None
            break
            
        case .showingTags:
            //            print("strings: \(strings[indexPath.row]) sermontTag: \(sermonSelected?.tags)")
            
            cell.accessoryType = UITableViewCellAccessoryType.None
            
//            if (selectedSermon?.tagsArray?.indexOf(strings![index]) != nil) {
//                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
//            } else {
//                cell.accessoryType = UITableViewCellAccessoryType.None
//            }
            break
            
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) sermontTag: \(Globals.sermonTag)")
            let string = strings![index]
            
            switch Globals.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(Globals.sermonTagsSelected)!.indexOf(string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
                break
            
            case Constants.ALL:
                if ((Globals.sermonTagsSelected == nil) && (strings![index] == Constants.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingSection:
            cell.accessoryType = UITableViewCellAccessoryType.None
            break
            
        case .selectingGrouping:
            if (Constants.groupings[index] == Globals.grouping) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == Globals.sorting) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            break
            
        case .selectingShow:
            cell.accessoryType = UITableViewCellAccessoryType.None
            break
        
        default:
            break
        }

        cell.textLabel?.text = strings![index]

        return cell
    }

    override func tableView(TableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let cell = tableView.cellForRowAtIndexPath(indexPath)

        var index = -1
        if (showIndex) {
            index = self.section.indexes != nil ? self.section.indexes![indexPath.section]+indexPath.row : -1
        } else {
            index = indexPath.row
        }

        delegate?.rowClickedAtIndex(index, strings: self.strings!, purpose: self.purpose!, sermon: self.selectedSermon)
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
