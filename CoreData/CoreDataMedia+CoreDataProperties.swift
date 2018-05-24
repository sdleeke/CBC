//
//  CoreDataMedia+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreDataMedia {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataMedia> {
        return NSFetchRequest<CoreDataMedia>(entityName: "CoreDataMedia")
    }

    @NSManaged public var id: String?
    @NSManaged public var dict: NSSet?
    @NSManaged public var htmlTranscript: MediaTranscript?

}

// MARK: Generated accessors for dict
extension CoreDataMedia {

    @objc(addDictObject:)
    @NSManaged public func addToDict(_ value: MediaProperty)

    @objc(removeDictObject:)
    @NSManaged public func removeFromDict(_ value: MediaProperty)

    @objc(addDict:)
    @NSManaged public func addToDict(_ values: NSSet)

    @objc(removeDict:)
    @NSManaged public func removeFromDict(_ values: NSSet)

}
