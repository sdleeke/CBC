//
//  LexiconEntry+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 1/8/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData

extension LexiconEntry
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LexiconEntry>
    {
        return NSFetchRequest<LexiconEntry>(entityName: "LexiconEntry")
    }

    @NSManaged public var count: Int64
    @NSManaged public var lexiconWord: LexiconWord?
    @NSManaged public var lexiconTranscript: LexiconTranscript?
}
