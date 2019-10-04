//
//  PopoverTableViewCell.swift
//  CBC
//
//  Created by Steve Leeke on 12/11/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

/**
 PTVC cell
 */
class PopoverTableViewCell: UITableViewCell
{
    deinit {
        debug(self)
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var titleToBottom: NSLayoutConstraint!
    @IBOutlet weak var titleToTop: NSLayoutConstraint!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
}
