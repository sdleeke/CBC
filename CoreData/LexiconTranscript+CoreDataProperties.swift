//
//  LexiconTranscript+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 1/8/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension LexiconTranscript {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LexiconTranscript> {
        return NSFetchRequest<LexiconTranscript>(entityName: "LexiconTranscript")
    }

    @NSManaged public var id: String?
    @NSManaged public var category: String?
    @NSManaged public var lexiconEntries: NSSet?

}

// MARK: Generated accessors for lexiconEntries
extension LexiconTranscript {

    @objc(addLexiconEntriesObject:)
    @NSManaged public func addToLexiconEntries(_ value: LexiconEntry)

    @objc(removeLexiconEntriesObject:)
    @NSManaged public func removeFromLexiconEntries(_ value: LexiconEntry)

    @objc(addLexiconEntries:)
    @NSManaged public func addToLexiconEntries(_ values: NSSet)

    @objc(removeLexiconEntries:)
    @NSManaged public func removeFromLexiconEntries(_ values: NSSet)

}
