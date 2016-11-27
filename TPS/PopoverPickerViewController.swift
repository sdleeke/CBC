//
//  PopoverDatePickerViewController.swift
//  RentBuddy
//
//  Created by Steve Leeke on 5/11/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverPickerControllerDelegate
{
    func stringPicked(_ string:String?)
}

class PopoverPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    var delegate : PopoverPickerControllerDelegate?
    
    var strings:[String]?
    var string:String?
    
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var selectButton: UIButton!
    
    @IBAction func selectButtonAction(sender: UIButton)
    {
        print("\(string)")
        delegate?.stringPicked(string)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        picker.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        print(string)
//        print(strings)
        
        if string != nil {
            if let index = strings?.index(of:string!) {
                picker.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        self.preferredContentSize = CGSize(width: 300, height: 300)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return strings != nil ? strings!.count : 0
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }
        
//        label.font = UIFont(name: "System", size: 16.0)
        label.textAlignment = .center
        
        label.text = strings?[row]
        
        return label
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return strings?[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        string = strings?[row]
    }
    
}
