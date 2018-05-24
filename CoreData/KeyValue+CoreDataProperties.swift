//
//  KeyValue+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension KeyValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyValue> {
        return NSFetchRequest<KeyValue>(entityName: "KeyValue")
    }

    @NSManaged public var value: String?
    @NSManaged public var key: NSSet?

}

// MARK: Generated accessors for key
extension KeyValue {

    @objc(addKeyObject:)
    @NSManaged public func addToKey(_ value: Key)

    @objc(removeKeyObject:)
    @NSManaged public func removeFromKey(_ value: Key)

    @objc(addKey:)
    @NSManaged public func addToKey(_ values: NSSet)

    @objc(removeKey:)
    @NSManaged public func removeFromKey(_ values: NSSet)

}
