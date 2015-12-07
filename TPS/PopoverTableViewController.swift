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
    func rowClickedAtIndex(index:Int, strings:[String], purpose:PopoverPurpose)
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
//    var sections = [String]()
//    var sectionIndexes = [Int]()
//    var sectionCounts = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
        if (strings != nil) {
            var max:Int = 0
            
            for string in strings! {
                if string.characters.count > max {
                    max = string.characters.count
                }
            }
            
    //        print("count: \(CGFloat(strings!.count)) rowHeight: \(tableView.rowHeight) height: \(height)")
            
            var width = CGFloat(max * 10)
            if width < 200 {
                width = 200
            }
            var height = 45 * CGFloat(strings!.count) //35 tableView.rowHeight was -1 which I don't understand
            if height < 150 {
                height = 150
            }
            
            if showSectionHeaders {
                height = 1.5*height
            }
            
            self.preferredContentSize = CGSizeMake(width, height)

            if (showIndex) {
                let a = "A"
                
                section.titles = Array(Set(strings!.map({ (string:String) -> String in
                    return stringWithoutLeadingTheOrAOrAn(string)!.substringToIndex(a.endIndex)
                }))).sort() { $0 < $1 }
                
                var indexes = [Int]()
                var counts = [Int]()
                
                for sectionTitle in section.titles! {
                    var counter = 0
                    
                    for index in 0..<strings!.count {
                        if (sectionTitle == stringWithoutLeadingTheOrAOrAn(strings![index])!.substringToIndex(a.endIndex)) {
                            if (counter == 0) {
                                indexes.append(index)
                            }
                            counter++
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
        
        if (purpose == .selectingTags) && (Globals.sermonTagsSelected != nil) && (Globals.sermonTagsSelected != Constants.All) {
            let row = strings!.indexOf(Globals.sermonTagsSelected!)!
            let indexPath = NSIndexPath(forRow: row, inSection: 0)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
        }
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
        if (showIndex && showSectionHeaders) {
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.POPOVER_CELL_IDENTIFIER, forIndexPath: indexPath)

        var index = -1
        
        if (showIndex) {
            index = self.section.indexes != nil ? self.section.indexes![indexPath.section]+indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        // Configure the cell...
        switch purpose! {
        case .showingTags:
            //            print("strings: \(strings[indexPath.row]) sermontTag: \(sermonSelected?.tags)")
            
            if (selectedSermon?.tagsArray().indexOf(strings![index]) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
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
            if (strings?[index].lowercaseString == Globals.grouping?.lowercaseString) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            break
            
        case .selectingSorting:
            if (strings?[index].lowercaseString == Globals.sorting?.lowercaseString) {
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

        delegate?.rowClickedAtIndex(index, strings: self.strings!, purpose: self.purpose!)
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
