//
//  ModelObject.swift
//  Coppice
//
//  Created by Martin Pilkington on 26/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import Foundation

public enum ModelObjectUpdateErrors: Error, Equatable {
    case idsDontMatch
    case attributeNotFound(String)
    case modelControllerNotSet
}

public struct ModelPlistKey: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ModelPlistKey {
    public static let id = ModelPlistKey(rawValue: "id")
}

public indirect enum ModelPropertyConversion {
    case modelID
    case modelFile
    case array(ModelPropertyConversion)
    case dictionary([ModelPlistKey: ModelPropertyConversion])
}

//MARK: -
/// The protocol root for model objects, used where generics can't be
public protocol ModelObject: AnyObject {
    var id: ModelID { get set }
    static var modelType: ModelType { get }
    var modelController: ModelController? { get }
    var undoManager: UndoManager? { get }

    init()

    var otherProperties: [ModelPlistKey: Any] { get }

    static func modelID(with: UUID) -> ModelID
    static func modelID(withUUIDString: String) -> ModelID?

    //MARK: - Plist
    var plistRepresentation: [ModelPlistKey: Any] { get }

    /// Update the model using the supplied Plist values.
    ///
    /// Implementations should check the plist to see if IDs match before updating
    /// - Parameter plist: The plist to update
    func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws

    static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] { get }
}


extension ModelObject {
    public static func modelID(with uuid: UUID) -> ModelID {
        return ModelID(modelType: self.modelType, uuid: uuid)
    }

    public static func modelID(withUUIDString uuidString: String) -> ModelID? {
        return ModelID(modelType: self.modelType, uuidString: uuidString)
    }

    public var undoManager: UndoManager? {
        return self.modelController?.undoManager
    }

    public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
        return [:]
    }

    var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
        return Self.propertyConversions
    }
}


//MARK: -
/// A more extensive ModelObject protocol supporting undo, relationships, etc
public protocol CollectableModelObject: ModelObject, Hashable {
    var collection: ModelCollection<Self>? { get set }

    /// Called after the object was inserted into the collection. The `collection` property is guaranteed to get set when this is called
    func objectWasInserted()

    /// Called before the object will be deleted. The object should break any relationship
    func objectWasDeleted()

    /// Register an undo action for an attribute change
    /// - Parameter oldValue: The old value of the attribute
    /// - Parameter keyPath: The keypath of the attribute
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T)


    /// Register an undo action for a change to a replationship
    /// - Parameters:
    ///   - keyPath: The keypath of the relationship to change
    ///   - inverseKeyPath: The key path of the opposite relationship
    ///   - oldValue: The old value of the relationship
    func didChangeRelationship<T: CollectableModelObject>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, inverseKeyPath: KeyPath<T, Set<Self>>, oldValue: T?)

    /// Return the objects for a to-many relationship
    /// - Parameter keyPath: The keypath on the returned type that holds the inverse relationship
    func relationship<T: CollectableModelObject>(for keyPath: KeyPath<T, Self?>) -> Set<T>

    func performUpdate(_ updateBlock: (Self) -> Void)
}


//MARK: -
extension CollectableModelObject {
    public var modelController: ModelController? {
        return self.collection?.modelController
    }

    public var changePublisher: AnyPublisher<ModelCollection<Self>.Change, Never>? {
        return self.collection?.changePublisher.filter { $0.object.id == self.id }.eraseToAnyPublisher()
    }

    public func changePublisher<T>(for keyPath: KeyPath<Self, T>) -> AnyPublisher<T, Never>? {
        return self.collection?.changePublisher
            .filter { $0.object.id == self.id && $0.didUpdate(keyPath) }
            .map { $0.object[keyPath: keyPath] }
            .eraseToAnyPublisher()
    }

    @discardableResult public static func create(in modelController: ModelController, setupBlock: ((Self) -> Void)? = nil) -> Self {
        return modelController.collection(for: Self.self).newObject(setupBlock: setupBlock)
    }

    public func objectWasInserted() {}

    public func objectWasDeleted() {}

    public func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T) {
        let id = self.id
        self.collection?.notifyOfChange(to: self, changeType: .update, keyPath: keyPath)
        self.collection?.registerUndoAction(withName: nil) { (collection) in
            collection.setValue(oldValue, for: keyPath, ofObjectWithID: id)
        }
    }

    public func didChangeRelationship<T: CollectableModelObject>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, inverseKeyPath: KeyPath<T, Set<Self>>, oldValue: T?) {
        guard let relationshipObject = oldValue ?? self[keyPath: keyPath],
              let selfCollection = self.collection,
              let relationshipCollection = relationshipObject.collection
        else {
                return
        }
        let id = self.id
        let oldID = oldValue?.id
        selfCollection.notifyOfChange(to: self, changeType: .update, keyPath: keyPath)
        selfCollection.registerUndoAction(withName: nil) { (collection) in
            var value: T? = nil
            if let objectID = oldID,
               let oldObject = relationshipCollection.objectWithID(objectID)
            {
                value = oldObject
            }
            collection.setValue(value, for: keyPath, ofObjectWithID: id)
        }

        relationshipCollection.notifyOfChange(to: relationshipObject, changeType: .update, keyPath: inverseKeyPath)
    }

    public func relationship<T: CollectableModelObject>(for keyPath: KeyPath<T, Self?>) -> Set<T> {
        guard let modelController = self.modelController else {
            return Set<T>()
        }
        let collection = modelController.collection(for: T.self)
        return collection.objectsForRelationship(on: self, inverseKeyPath: keyPath)
    }

    public func performUpdate(_ updateBlock: (Self) -> Void) {
        self.modelController?.pushChangeGroup()
        updateBlock(self)
        self.modelController?.popChangeGroup()
    }

    public func delete() {
        self.collection?.delete(self)
    }
}


public struct ModelFile {
    public let type: String
    public let filename: String?
    public let data: Data?
    public let metadata: [String: Any]?

    public init(type: String, filename: String?, data: Data?, metadata: [String: Any]?) {
        self.type = type
        self.filename = filename
        self.data = data
        self.metadata = metadata
    }

    public var plistRepresentation: [String: Any] {
        var plist: [String: Any] = ["type": self.type]
        if let filename = self.filename {
            plist["filename"] = filename
        }
        if let metadata = self.metadata {
            plist["metadata"] = metadata
        }
        return plist
    }
}

extension ModelFile: PlistConvertable {
	func toPlistValue() throws -> PlistValue {
		var plist: [String: Any] = ["type": self.type]
		if let filename = self.filename {
			plist["filename"] = filename
		}
		if let metadata = self.metadata {
			plist["metadata"] = metadata
		}
		return plist
	}

	static func fromPlistValue(_ plistValue: PlistValue) throws -> ModelFile {
		guard
			let modelFileDict = plistValue as? [String: Any],
			let type = modelFileDict["type"] as? String
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}

		return ModelFile(type: type,
						 filename: modelFileDict["filename"] as? String,
						 data: modelFileDict["data"] as? Data,
						 metadata: modelFileDict["metadata"] as? [String: Any])
	}


}
