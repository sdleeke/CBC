//
//  LexiconStringNode+CoreDataProperties.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//
//

import Foundation
import CoreData


extension LexiconStringNode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LexiconStringNode> {
        return NSFetchRequest<LexiconStringNode>(entityName: "LexiconStringNode")
    }

    @NSManaged public var string: String?
    @NSManaged public var wordEnding: Bool
    @NSManaged public var stringNodes: NSSet?

}

// MARK: Generated accessors for stringNodes
extension LexiconStringNode {

    @objc(addStringNodesObject:)
    @NSManaged public func addToStringNodes(_ value: LexiconStringNode)

    @objc(removeStringNodesObject:)
    @NSManaged public func removeFromStringNodes(_ value: LexiconStringNode)

    @objc(addStringNodes:)
    @NSManaged public func addToStringNodes(_ values: NSSet)

    @objc(removeStringNodes:)
    @NSManaged public func removeFromStringNodes(_ values: NSSet)

}
