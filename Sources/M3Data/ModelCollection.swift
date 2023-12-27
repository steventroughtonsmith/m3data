//
//  ModelCollection.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import Foundation

public enum ModelChangeType: Equatable {
    case update
    case insert
    case delete
}


public class ModelCollection<ModelType: CollectableModelObject> {
    public class Change {
        public let object: ModelType
        public init(object: ModelType) {
            self.object = object
        }

        public private(set) var changeType: ModelChangeType = .update

        private var keyPaths = Set<PartialKeyPath<ModelType>>()
        public var updatedKeyPaths: Set<PartialKeyPath<ModelType>> {
            guard self.changeType == .update else {
                return Set()
            }
            return self.keyPaths
        }

        public func didUpdate<T>(_ keyPath: KeyPath<ModelType, T>) -> Bool {
            let partialKeyPath = keyPath as PartialKeyPath<ModelType>
            return self.updatedKeyPaths.contains(partialKeyPath)
        }

        public func registerChange(ofType changeType: ModelChangeType, keyPath: PartialKeyPath<ModelType>? = nil) {
            if changeType == .update {
                precondition(keyPath != nil, "Must supply a key path for an update change")
                self.keyPaths.insert(keyPath!)
            }
            self.changeType = changeType
        }
    }

    class ChangeGroup {
        private(set) var changes = [ModelType: Change]()
        private func change(for object: ModelType) -> Change {
            if let change = self.changes[object] {
                return change
            }

            let change = Change(object: object)
            self.changes[object] = change
            return change
        }

        func registerChange(to object: ModelType, changeType: ModelChangeType, keyPath: PartialKeyPath<ModelType>? = nil) {
            self.change(for: object).registerChange(ofType: changeType, keyPath: keyPath)
        }
    }

    public init() {}

    public weak var modelController: ModelController?

    public private(set) var all = Set<ModelType>()

    public func objectWithID(_ id: ModelID) -> ModelType? {
        return self.all.first { $0.id == id }
    }

    public func contains(_ object: ModelType) -> Bool {
        return self.all.contains(object)
    }

    public typealias ModelSetupBlock = (ModelType) -> Void
    @discardableResult public func newObject(setupBlock: ModelSetupBlock? = nil) -> ModelType {
        self.modelController?.pushChangeGroup()
        let newObject = ModelType()
        newObject.collection = self

        self.insert(newObject, notifyOfChange: false)
        self.disable([.undo, .change]) {
            setupBlock?(newObject)
        }
        self.notifyOfChange(to: newObject, changeType: .insert)
        self.modelController?.popChangeGroup()
        return newObject
    }

    private func insert(_ object: ModelType, notifyOfChange: Bool = true) {
        self.all.insert(object)

        self.registerUndoAction() { collection in
            collection.delete(object)
        }

        self.disableUndo {
            object.objectWasInserted()
        }

        if (notifyOfChange) {
            self.notifyOfChange(to: object, changeType: .insert)
        }
    }

    public func delete(_ object: ModelType) {
        if let index = self.all.firstIndex(where: { $0.id == object.id }) {
            self.registerUndoAction() { collection in
                collection.insert(object)
            }
            self.all.remove(at: index)
            self.disableUndo {
                object.objectWasDeleted()
            }
            self.notifyOfChange(to: object, changeType: .delete)
        }
    }


    //MARK: - Relationships
    public func objectsForRelationship<R: ModelObject>(on object: R, inverseKeyPath: KeyPath<ModelType, R?>) -> Set<ModelType> {
        return self.all.filter { $0[keyPath: inverseKeyPath]?.id == object.id }
    }


    //MARK: - Capabilities
    public func disable(_ capablities: ModelCollectionCapabilities, _ caller: () throws -> Void) rethrows {
        if capablities.contains(.undo) {
            self.modelController?.undoManager.disableUndoRegistration()
        }
        if capablities.contains(.change) {
            self.changeRegistrationEnabled = false
        }

        try caller()

        if capablities.contains(.undo) {
            self.modelController?.undoManager.enableUndoRegistration()
        }
        if capablities.contains(.change) {
            self.changeRegistrationEnabled = true
        }
    }


    //MARK: - Change Observation
    public let changePublisher = PassthroughSubject<Change, Never>()

    private var changeRegistrationEnabled = true

    public func notifyOfChange(to object: ModelType, changeType: ModelChangeType = .update, keyPath: PartialKeyPath<ModelType>? = nil) {
        guard self.changeRegistrationEnabled else {
            return
        }

        guard let currentChangeGroup = self.changeGroups.last else {
            let change = Change(object: object)
            change.registerChange(ofType: changeType, keyPath: keyPath)
            self.changePublisher.send(change)
            return
        }
        currentChangeGroup.registerChange(to: object, changeType: changeType, keyPath: keyPath)
    }

    private var changeGroups = [ChangeGroup]()


    //MARK: - Undo
    public func disableUndo(_ caller: () throws -> Void) rethrows {
        try self.disable(.undo, caller)
    }

    public func registerUndoAction(withName name: String? = nil, invocationBlock: @escaping (ModelCollection<ModelType>) -> Void) {
        guard let undoManager = self.modelController?.undoManager else {
            return
        }

        if let name = name {
            undoManager.setActionName(name)
        }
        undoManager.registerUndo(withTarget: self, handler: invocationBlock)
    }

    public func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ModelType, Value>, ofObjectWithID id: ModelID) {
        guard let object = self.objectWithID(id) else {
            return
        }
        object[keyPath: keyPath] = value
    }
}

extension ModelCollection: ModelChangeGroupHandler {
    public func pushChangeGroup() {
        self.changeGroups.append(ChangeGroup())
    }

    public func popChangeGroup() {
        guard let changeGroup = self.changeGroups.popLast() else {
            return
        }
        
        for (_, change) in changeGroup.changes {
            self.changePublisher.send(change)
        }
    }
}

//MARK: - Type Erasure
public class AnyModelCollection {
    public let modelCollection: Any
    init(modelCollection: Any) {
        self.modelCollection = modelCollection
    }

    fileprivate var allImp: (() -> [any CollectableModelObject])?
    public var all: [any CollectableModelObject] {
        return allImp?() ?? []
    }

    fileprivate var objectWithIDImp: ((ModelID) -> (any CollectableModelObject)?)?
    public func objectWithID(_ id: ModelID) -> (any CollectableModelObject)? {
        return self.objectWithIDImp?(id)
    }

    fileprivate var containsObjectImp: ((any CollectableModelObject) -> Bool)?
    public func contains(_ object: any CollectableModelObject) -> Bool {
        return self.containsObjectImp?(object) ?? false
    }

    fileprivate var disableUndoImp: ((() throws -> Void) throws -> Void)?
    public func disableUndo(_ caller: () throws -> Void) throws {
        try self.disableUndoImp?(caller)
    }

    fileprivate var deleteImp: ((any CollectableModelObject) -> Void)?
    public func delete(_ object: any CollectableModelObject) {
        self.deleteImp?(object)
    }

    public typealias ModelSetupBlock = (any CollectableModelObject) -> Void
    fileprivate var newObjectImp: (((ModelSetupBlock)?) -> (any CollectableModelObject))?
    @discardableResult public func newObject(setupBlock: (ModelSetupBlock)? = nil) -> any CollectableModelObject {
        return self.newObjectImp!(setupBlock)
    }

    fileprivate var pushChangeGroupImp: () -> Void = {}
    public func pushChangeGroup() {
        self.pushChangeGroupImp()
    }

    fileprivate var popChangeGroupImp: () -> Void = {}
    public func popChangeGroup() {
        self.popChangeGroupImp()
    }
}

extension ModelCollection {
    func toAnyModelCollection() -> AnyModelCollection {
        let anyCollection = AnyModelCollection(modelCollection: self)

        anyCollection.allImp = {
            return Array(self.all)
        }

        anyCollection.objectWithIDImp = { modelID in
            return self.objectWithID(modelID)
        }

        anyCollection.containsObjectImp = { object in
            guard let typedObject = object as? ModelType else {
                return false
            }
            return self.contains(typedObject)
        }

        anyCollection.disableUndoImp = { closure in
            try self.disableUndo(closure)
        }

        anyCollection.deleteImp = { object in
            guard let typedObject = object as? ModelType else {
                return
            }
            self.delete(typedObject)
        }

        anyCollection.newObjectImp = { setupBlock in
            return self.newObject(setupBlock: setupBlock)
        }

        anyCollection.pushChangeGroupImp = {
            return self.pushChangeGroup()
        }

        anyCollection.popChangeGroupImp = {
            return self.popChangeGroup()
        }

        return anyCollection
    }
}

public struct ModelCollectionCapabilities: OptionSet {
    public let rawValue: UInt

    public static let undo = ModelCollectionCapabilities(rawValue: 1 << 0)
    public static let change = ModelCollectionCapabilities(rawValue: 1 << 1)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
