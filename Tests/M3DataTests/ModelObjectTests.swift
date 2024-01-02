//
//  ModelObjectTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import M3Data
import XCTest

class ModelObjectTests: XCTestCase {
    var modelController: TestModelController!
    var modelCollection: ModelCollection<TestCollectableModelObject>!

    override func setUp() {
        super.setUp()
        self.modelController = TestModelController()
        self.modelCollection = ModelCollection<TestCollectableModelObject>()
        self.modelCollection.modelController = self.modelController
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
        self.modelCollection = nil
    }

    //MARK: - ModelObject
    func test_modelIDWithUUID_returnsModelIDWithObjectsTypeAndSuppliedUUID() {
        let expectedUUID = UUID()
        let modelID = TestModelObject.modelID(with: expectedUUID)
        XCTAssertEqual(modelID.uuid, expectedUUID)
        XCTAssertEqual(modelID.modelType, TestModelObject.modelType)
    }

    func test_modelIDWithUUIDString_returnsModelIDWithObjectsTypeAndUUIDFromSuppliedString() throws {
        let expectedUUID = UUID()
        let modelID = try XCTUnwrap(TestModelObject.modelID(withUUIDString: expectedUUID.uuidString))
        XCTAssertEqual(modelID.uuid, expectedUUID)
        XCTAssertEqual(modelID.modelType, TestModelObject.modelType)
    }

    func test_modelIDWithUUIDString_returnsNilIfSuppliedStringIsNotUUID() {
        XCTAssertNil(TestModelObject.modelID(withUUIDString: ""))
    }


    //MARK: - CollectableModelObject.modelController
    func test_modelController_returnsCollectionsModelController() {
        let model = TestCollectableModelObject()
        model.collection = self.modelCollection

        XCTAssertEqual((model.modelController as! TestModelController), self.modelController)
    }


    //MARK: - CollectableModelObject.changePublisher
    func test_changePublisher_returnsPublisherFromChangePublisher() throws {
        let model = TestCollectableModelObject()
        model.collection = self.modelCollection

        XCTAssertNotNil(model.changePublisher)
    }

    func test_changePublisher_onlyIncludesObjectInFilter() throws {
        let model = TestCollectableModelObject()
        model.collection = self.modelCollection

        let observer1Expectation = self.expectation(description: "Observer 1 Notified")
        let publisher = try XCTUnwrap(model.changePublisher)
        let subscriber = publisher.sink { _ in
            observer1Expectation.fulfill()
        }

        self.modelCollection.notifyOfChange(to: model, changeType: .insert)
        self.modelCollection.notifyOfChange(to: TestCollectableModelObject(), changeType: .insert)
        self.wait(for: [observer1Expectation], timeout: 1)
        subscriber.cancel()
    }


    //MARK: - Model File
    
}
