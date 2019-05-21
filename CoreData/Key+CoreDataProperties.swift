//
//  Key+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension Key {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Key> {
        return NSFetchRequest<Key>(entityName: "Key")
    }

    @NSManaged public var key: String?
    @NSManaged public var mediaItem: NSSet?
    @NSManaged public var value: KeyValue?

}

// MARK: Generated accessors for mediaItem
extension Key {

    @objc(addMediaItemObject:)
    @NSManaged public func addToMediaItem(_ value: Media)

    @objc(removeMediaItemObject:)
    @NSManaged public func removeFromMediaItem(_ value: Media)

    @objc(addMediaItem:)
    @NSManaged public func addToMediaItem(_ values: NSSet)

    @objc(removeMediaItem:)
    @NSManaged public func removeFromMediaItem(_ values: NSSet)

}
