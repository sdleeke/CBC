//
//  MediaProperty+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension MediaProperty {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaProperty> {
        return NSFetchRequest<MediaProperty>(entityName: "MediaProperty")
    }

    @NSManaged public var property: String?
    @NSManaged public var mediaItem: NSSet?
    @NSManaged public var value: MediaValue?

}

// MARK: Generated accessors for mediaItem
extension MediaProperty {

    @objc(addMediaItemObject:)
    @NSManaged public func addToMediaItem(_ value: CoreDataMedia)

    @objc(removeMediaItemObject:)
    @NSManaged public func removeFromMediaItem(_ value: CoreDataMedia)

    @objc(addMediaItem:)
    @NSManaged public func addToMediaItem(_ values: NSSet)

    @objc(removeMediaItem:)
    @NSManaged public func removeFromMediaItem(_ values: NSSet)

}
