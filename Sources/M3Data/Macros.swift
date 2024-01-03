//
//  File.swift
//  
//
//  Created by Martin Pilkington on 21/12/2023.
//

import Foundation

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@attached(member, names: named(modelType), named(id), named(collection), named(init), named(otherProperties), named(plistRepresentation), named(update(fromPlistRepresentation:)), named(modelFileProperties))
@attached(extension, conformances: CollectableModelObject, Equatable, Hashable, names: named(hash(into:)), named(==), named(PlistKeys), arbitrary)
public macro Model() = #externalMacro(module: "M3DataMacros", type: "ModelMacro")


@attached(accessor, names: named(get), named(set))
@attached(peer, names: arbitrary)
public macro Attribute(optional: Bool = false,
					   default: Any? = nil,
					   persistenceName: String? = nil,
					   requiresTransform: Bool = false,
					   isModelFile: Bool = false) = #externalMacro(module: "M3DataMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: arbitrary)
public macro Relationship(inverse: AnyKeyPath, persistenceName: String? = nil) = #externalMacro(module: "M3DataMacros", type: "RelationshipMacro")
