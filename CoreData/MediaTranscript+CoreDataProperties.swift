//
//  MediaTranscript+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension MediaTranscript {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaTranscript> {
        return NSFetchRequest<MediaTranscript>(entityName: "MediaTranscript")
    }

    @NSManaged public var html: String?
    @NSManaged public var media: CoreDataMedia?

}
