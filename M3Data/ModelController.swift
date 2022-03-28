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
    var allCollections: [ModelType: Any] { get set }
    var settings: ModelSettings { get }
    @discardableResult func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func removeModelCollection<T: CollectableModelObject>(for type: T.Type)

    func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func object(with id: ModelID) -> ModelObject?

    func disableUndo(_ caller: () throws -> Void) rethrows
}

extension ModelController {
    @discardableResult public func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        let modelCollection = ModelCollection<T>()
        modelCollection.modelController = self
        self.allCollections[type.modelType] = modelCollection
        return modelCollection
    }

    public func removeModelCollection<T: CollectableModelObject>(for type: T.Type) {
        self.allCollections.removeValue(forKey: type.modelType)
    }

    public func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        guard let model = self.allCollections[type.modelType] as? ModelCollection<T> else {
            preconditionFailure("Collection with type '\(type.modelType)' does not exist")
        }
        return model
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
