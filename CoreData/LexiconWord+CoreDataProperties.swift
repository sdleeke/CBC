//
//  LexiconWord+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension LexiconWord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LexiconWord> {
        return NSFetchRequest<LexiconWord>(entityName: "LexiconWord")
    }

    @NSManaged public var word: String?
    @NSManaged public var lexiconEntries: NSSet?

}

// MARK: Generated accessors for lexiconEntries
extension LexiconWord {

    @objc(addLexiconEntriesObject:)
    @NSManaged public func addToLexiconEntries(_ value: LexiconEntry)

    @objc(removeLexiconEntriesObject:)
    @NSManaged public func removeFromLexiconEntries(_ value: LexiconEntry)

    @objc(addLexiconEntries:)
    @NSManaged public func addToLexiconEntries(_ values: NSSet)

    @objc(removeLexiconEntries:)
    @NSManaged public func removeFromLexiconEntries(_ values: NSSet)

}
