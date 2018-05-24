//
//  MediaValue+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension MediaValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaValue> {
        return NSFetchRequest<MediaValue>(entityName: "MediaValue")
    }

    @NSManaged public var value: String?
    @NSManaged public var key: NSSet?

}

// MARK: Generated accessors for key
extension MediaValue {

    @objc(addKeyObject:)
    @NSManaged public func addToKey(_ value: MediaProperty)

    @objc(removeKeyObject:)
    @NSManaged public func removeFromKey(_ value: MediaProperty)

    @objc(addKey:)
    @NSManaged public func addToKey(_ values: NSSet)

    @objc(removeKey:)
    @NSManaged public func removeFromKey(_ values: NSSet)

}
