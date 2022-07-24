//
//  ModelController.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

public protocol ModelController: AnyObject, ModelChangeGroupHandler {
    var undoManager: UndoManager { get }
    var allCollections: [ModelType: AnyModelCollection] { get set }
    var settings: ModelSettings { get }

    @discardableResult func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func removeModelCollection<T: CollectableModelObject>(for type: T.Type)

    func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func anyCollection(for modelType: ModelType) -> AnyModelCollection
    func object(with id: ModelID) -> (any CollectableModelObject)?

    func disableUndo(_ caller: () throws -> Void) rethrows
}

extension ModelController {
    @discardableResult public func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        let modelCollection = ModelCollection<T>()
        modelCollection.modelController = self
        self.allCollections[type.modelType] = modelCollection.toAnyModelCollection()
        return modelCollection
    }

    public func removeModelCollection<T: CollectableModelObject>(for type: T.Type) {
        self.allCollections.removeValue(forKey: type.modelType)
    }

    public func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        guard let model = self.allCollections[type.modelType]?.modelCollection as? ModelCollection<T> else {
            preconditionFailure("Collection with type '\(type.modelType)' does not exist")
        }
        return model
    }

    public func anyCollection(for modelType: ModelType) -> AnyModelCollection {
        guard let collection = self.allCollections[modelType] else {
            preconditionFailure("Collection with type '\(modelType)' does not exist")
        }
        return collection
    }

    public func object(with id: ModelID) -> (any CollectableModelObject)? {
        return self.anyCollection(for: id.modelType).objectWithID(id)
    }

    public func pushChangeGroup() {
        self.allCollections.values
            .compactMap { $0 as? ModelChangeGroupHandler }
            .forEach { $0.pushChangeGroup() }
    }

    public func popChangeGroup() {
        self.allCollections.values
            .compactMap { $0 as? ModelChangeGroupHandler }
            .forEach { $0.popChangeGroup() }
    }

    public func disableUndo(_ caller: () throws -> Void) rethrows {
        self.undoManager.disableUndoRegistration()
        try caller()
        self.undoManager.enableUndoRegistration()
    }
}
