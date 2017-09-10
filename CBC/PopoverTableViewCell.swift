//
//  PopoverTableViewCell.swift
//  CBC
//
//  Created by Steve Leeke on 12/11/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class PopoverTableViewCell: UITableViewCell
{
    @IBOutlet weak var title: UILabel!

//    override func addSubview(_ view: UIView)
//    {
//        super.addSubview(view)
//        
//        let buttonFont = UIFont(name: Constants.FA.name, size: Constants.FA.ACTION_ICONS_FONT_SIZE)
//        let confirmationClass: AnyClass = NSClassFromString("UITableViewCellDeleteConfirmationView")!
//        
//        // replace default font in swipe buttons
//        let s = subviews.flatMap({$0}).filter { $0.isKind(of: confirmationClass) }
//        
//        for sub in s {
//            for button in sub.subviews {
//                if let b = button as? UIButton {
//                    b.titleLabel?.font = buttonFont
//                }
//            }
//        }
//    }
}
