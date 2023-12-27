//
//  ModelControllerTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import M3Data
import XCTest

class ModelControllerTests: XCTestCase {
    //MARK: - addModelCollection(for:)
    func test_addModelCollectionForType_addsNewCollectionToAllCollections() {
        let modelController = ModelControllerForTests()
        modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertNotNil(modelController.allCollections[TestCollectableModelObject.modelType])
    }

    func test_addModelCollectionForType_returnsModelCollectionThatWasAddedToAllCollections() {
        let modelController = ModelControllerForTests()
        let collection = modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertTrue(modelController.allCollections[TestCollectableModelObject.modelType]?.modelCollection as? ModelCollection<TestCollectableModelObject> === collection)
    }

    func test_addModelCollectionForType_setsModelControllerOfNewCollectionToSelf() {
        let modelController = ModelControllerForTests()
        let collection = modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertTrue(collection.modelController === modelController)
    }


    //MARK: - removeModelController(for:)
    func test_removeModelControllerForType_removesControllerMatchingType() {
        let modelController = ModelControllerForTests()
        modelController.addModelCollection(for: TestCollectableModelObject.self)

        modelController.removeModelCollection(for: TestCollectableModelObject.self)

        XCTAssertNil(modelController.allCollections[TestCollectableModelObject.modelType])
    }


    //MARK: - collection(for:)
    func test_collectionForType_returnsCollectionMatchingSuppliedType() {
        let modelController = ModelControllerForTests()
        let expectedCollection = modelController.addModelCollection(for: TestCollectableModelObject.self)

        let collection = modelController.collection(for: TestCollectableModelObject.self)
        XCTAssertTrue(collection === expectedCollection)
    }


    //MARK: - disableUndo(_:)
    func test_disableUndo_disablesUndoWhileInSuppliedBlock() throws {
        let modelController = ModelControllerForTests()
        XCTAssertTrue(modelController.undoManager.isUndoRegistrationEnabled)
        var blockCalled = false
        modelController.disableUndo {
            XCTAssertFalse(modelController.undoManager.isUndoRegistrationEnabled)
            blockCalled = true
        }
        XCTAssertTrue(blockCalled)
    }

    func test_disableUndo_reenablesUndoAfterCall() throws {
        let modelController = ModelControllerForTests()
        XCTAssertTrue(modelController.undoManager.isUndoRegistrationEnabled)
        var blockCalled = false
        modelController.disableUndo {
            blockCalled = true
        }
        XCTAssertTrue(blockCalled)
        XCTAssertTrue(modelController.undoManager.isUndoRegistrationEnabled)
    }
}



class ModelControllerForTests: ModelController {
    let undoManager: UndoManager = UndoManager()

    var allCollections: [ModelType: AnyModelCollection] = [:]

    var settings = ModelSettings()

    func object(with id: ModelID) -> ModelObject? {
        return nil
    }
}
