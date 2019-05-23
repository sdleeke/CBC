//
//  ScripturePickerViewController.swift
//  CBC
//
//  Created by Steve Leeke on 4/8/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension ScripturePickerViewController : UIPickerViewDataSource
{
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return includeVerses ? 4 : 3  // Compact width => 3, otherwise 5?  (beginning and ending verses)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var numberOfRows = 1
        
        switch component {
        case 0:
            numberOfRows = 2 // N.T. or O.T.
            break
            
        case 1:
            if scripture?.picked.testament != nil, let books = scripture?.picked.picker.books {
                numberOfRows = books.count
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            guard scripture?.picked.testament != nil else {
                numberOfRows = 0
                break
            }
            
            guard scripture?.picked.book != nil else {
                numberOfRows = 0
                break
            }
            
            if let chapters = scripture?.picked.picker.chapters {
                numberOfRows = chapters.count
            }
            break
            
        case 3:
            guard includeVerses else {
                numberOfRows = 0
                break
            }
            
            guard scripture?.picked.testament != nil else {
                numberOfRows = 0
                break
            }
            
            guard scripture?.picked.book != nil else {
                numberOfRows = 0
                break
            }
            
            guard scripture?.picked.chapter > 0 else {
                numberOfRows = 0
                break
            }
            
            if let verses = scripture?.picked.picker.verses {
                numberOfRows = verses.count
            }
            break
            
        default:
            break
        }
        
        return numberOfRows
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = (view as? UILabel) ?? UILabel()
        
        if let title = title(forRow: row, forComponent: component) {
            label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.body)
        }
        
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
            guard scripture?.picked.testament != nil else {
                break
            }
            
            if let book = scripture?.picked.picker.books?[row] {
                return book
            }
            break
            
        case 2:
            guard scripture?.picked.testament != nil else {
                break
            }
            
            guard scripture?.picked.book != nil else {
                break
            }
            
            if let chapters = scripture?.picked.picker.chapters {
                return "\(chapters[row])"
            }
            break
            
        case 3:
            guard scripture?.picked.testament != nil else {
                break
            }
            
            guard scripture?.picked.book != nil else {
                break
            }
            
            //            if scripture?.picked.chapter > 0 {
            //                return "1"
            //            }
            
            if let verses = scripture?.picked.picker.verses {
                return "\(verses[row])"
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
}

extension ScripturePickerViewController : UIPickerViewDelegate
{
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
    {
        // These should be dynamic
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch component {
        case 0: // Testament
            switch row {
            case 0:
                scripture?.picked.testament = Constants.OT
                break
                
            case 1:
                scripture?.picked.testament = Constants.NT
                break
                
            default:
                break
            }
            
            if let testament = scripture?.picked.testament {
                switch testament {
                case Constants.OT:
                    scripture?.picked.picker.books = Constants.OLD_TESTAMENT_BOOKS
                    break
                    
                case Constants.NT:
                    scripture?.picked.picker.books = Constants.NEW_TESTAMENT_BOOKS
                    break
                    
                default:
                    break
                }
            }
            
            scripture?.picked.book = scripture?.picked.picker.books?[0]
            
            updatePicker()
            
            if let chapter = scripture?.picked.picker.chapters?[0] {
                scripture?.picked.chapter = chapter
            }
            
            pickerView.reloadAllComponents()
            
            if pickerView.numberOfComponents > 1 {
                pickerView.selectRow(0, inComponent: 1, animated: true)
            }
            
            if pickerView.numberOfComponents > 2 {
                pickerView.selectRow(0, inComponent: 2, animated: true)
            }
            
            updateReferenceLabel()
            break
            
        case 1: // Book
            guard scripture?.picked.testament != nil else {
                break
            }
            
            scripture?.picked.book = scripture?.picked.picker.books?[row]
            
            updatePicker()
            
            if let chapter = scripture?.picked.picker.chapters?[0] {
                scripture?.picked.chapter = chapter
            }
            
            pickerView.reloadAllComponents()
            
            if pickerView.numberOfComponents > 2 {
                pickerView.selectRow(0, inComponent: 2, animated: true)
            }
            
            updateReferenceLabel()
            break
            
        case 2: // Chapter
            guard scripture?.picked.testament != nil else {
                break
            }
            
            guard scripture?.picked.book != nil else {
                break
            }
            
            if let chapter = scripture?.picked.picker.chapters?[row] {
                scripture?.picked.chapter = chapter
            }
            
            updatePicker()
            
            if let verse = scripture?.picked.picker.verses?[0] {
                scripture?.picked.verse = verse
            }
            
            pickerView.reloadAllComponents()
            
            if pickerView.numberOfComponents > 3 {
                pickerView.selectRow(0, inComponent: 3, animated: true)
            }
            
            updateReferenceLabel()
            break
            
        case 3: // Verse
            guard scripture?.picked.testament != nil else {
                break
            }
            
            guard scripture?.picked.book != nil else {
                break
            }
            
            guard scripture?.picked.chapter > 0 else {
                break
            }
            
            if let verse = scripture?.picked.picker.verses?[row] {
                scripture?.picked.verse = verse
            }
            
            //            pickerView.reloadAllComponents()
            
            updateReferenceLabel()
            break
            
        default:
            break
        }
        
        show?()
    }
}

class ScripturePickerViewController : CBCViewController
{
    deinit {
        debug(self)
        // Breakpoint won't work without something here.
        // Strange.  Other breakpoints in other empty deinit's work fine.
        print("deinit:ScripturePicker")
    }
    
    weak var scripture:Scripture?
    var includeVerses = false

    @IBOutlet weak var scripturePicker: UIPickerView!
    
    var show : (()->())?
    
    func updatePicker()
    {
        if scripture?.picked.testament == nil {
            scripture?.picked.testament = Constants.OT
        }
        
        guard let selectedTestament = scripture?.picked.testament else {
            return
        }
        
        guard !selectedTestament.isEmpty else {
            return
        }
        
        switch selectedTestament {
        case Constants.OT:
            scripture?.picked.picker.books = Constants.OLD_TESTAMENT_BOOKS
            break
            
        case Constants.NT:
            scripture?.picked.picker.books = Constants.NEW_TESTAMENT_BOOKS
            break
            
        default:
            break
        }
        
        if scripture?.picked.book == nil {
            scripture?.picked.book = scripture?.picked.picker.books?[0]
        }
        
        var maxChapters = 0
        switch selectedTestament {
        case Constants.OT:
            if let index = scripture?.picked.book?.bookNumberInBible {
                maxChapters = Constants.OLD_TESTAMENT_CHAPTERS[index]
            }
            break
            
        case Constants.NT:
            if let index = scripture?.picked.book?.bookNumberInBible {
                maxChapters = Constants.NEW_TESTAMENT_CHAPTERS[index - Constants.OLD_TESTAMENT_BOOKS.count]
            }
            break
            
        default:
            break
        }
        
        var chapters = [Int]()
        if maxChapters > 0 {
            for i in 1...maxChapters {
                chapters.append(i)
            }
        }
        scripture?.picked.picker.chapters = chapters
        
        if scripture?.picked.chapter == 0, let chapter = scripture?.picked.picker.chapters?[0] {
            scripture?.picked.chapter = chapter
        }
        
        if includeVerses, let index = scripture?.picked.book?.bookNumberInBible, let chapter = scripture?.picked.chapter {
            var maxVerses = 0
            switch selectedTestament {
            case Constants.OT:
                maxVerses = Constants.OLD_TESTAMENT_VERSES[index][chapter]
                break
                
            case Constants.NT:
                maxVerses = Constants.NEW_TESTAMENT_VERSES[index - Constants.OLD_TESTAMENT_BOOKS.count][chapter]
                break
                
            default:
                break
            }
            var verses = [Int]()
            if maxVerses > 0 {
                for i in 1...maxVerses {
                    verses.append(i)
                }
            }
            scripture?.picked.picker.verses = verses
            
            if scripture?.picked.verse == 0, let verse = scripture?.picked.picker.verses?[0] {
                scripture?.picked.verse = verse
            }
        }
        
        scripturePicker.reloadAllComponents()
        
        //        guard let selectedTestament = scripture?.picked.testament else {
        //            return
        //        }
        
        if let index = Constants.TESTAMENTS.firstIndex(of: selectedTestament) {
            scripturePicker.selectRow(index, inComponent: 0, animated: false)
        }
        
        if let selectedBook = scripture?.picked.book, let index = scripture?.picked.picker.books?.firstIndex(of: selectedBook) {
            scripturePicker.selectRow(index, inComponent: 1, animated: false)
        }
        
        if let chapter = scripture?.picked.chapter, chapter > 0, let index = scripture?.picked.picker.chapters?.firstIndex(of: chapter) {
            scripturePicker.selectRow(index, inComponent: 2, animated: false)
        }
        
        guard includeVerses else {
            return
        }
        
        if let verse = scripture?.picked.verse, verse > 0, let index = scripture?.picked.picker.verses?.firstIndex(of: verse) {
            scripturePicker.selectRow(index, inComponent: 3, animated: false)
        }
    }
    
    func updateReferenceLabel()
    {
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
                                                            // In case it is embedded
//        if let navigationController = navigationController, navigationController.topViewController == self, modalPresentationStyle != .popover {
//            Alerts.shared.topViewController.append(navigationController)
//        }
        
//        orientation = UIDevice.current.orientation
//
//        addNotifications()
        
//        navigationController?.isToolbarHidden = true
        
        if navigationController?.modalPresentationStyle == .popover {
            preferredContentSize = CGSize(width:  view.frame.width,
                                          height: scripturePicker.frame.height + 60)
        } else {
            
        }
        
//        setupBarButtons()
        
        if scripture?.picked.reference == nil, let reference = scripture?.reference, let books = reference.books, books.count > 0 {
            if let books = scripture?.booksChaptersVerses?.books?.sorted(by: { scripture?.reference?.range(of: $0)?.lowerBound < scripture?.reference?.range(of: $1)?.lowerBound }) {
                let book = books[0]
                
                scripture?.picked.testament = book.testament.translateTestament
                scripture?.picked.book = book
                
                if let chapters = scripture?.booksChaptersVerses?[book]?.keys.sorted() {
                    scripture?.picked.chapter = chapters[0]
                }
            }
            
            self.updatePicker()
        } else {
            updatePicker()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
//        if Alerts.shared.topViewController.last == navigationController {
//            Alerts.shared.topViewController.removeLast()
//        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
    }
}
