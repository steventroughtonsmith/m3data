//
//  ModelWriter.swift
//  M3Data
//
//  Created by Martin Pilkington on 25/07/2022.
//

import Foundation

public class ModelWriter {
    public let modelController: ModelController
    public let plist: ModelPlist.Type
    public init(modelController: ModelController, plist: ModelPlist.Type) {
        self.modelController = modelController
        self.plist = plist
    }

    public func generateFileWrappers() throws -> (data: FileWrapper, content: FileWrapper) {
        var content = [ModelFile]()

        let dataPlist = self.plist.init()
        dataPlist.settings = self.modelController.settings.plistRepresentation

        for supportedType in self.plist.supportedTypes {
            let (plistRepresentations, modelContents) = self.generateData(for: supportedType.modelType)
            try dataPlist.setPlistRepresentations(plistRepresentations, for: supportedType.modelType)
            content.append(contentsOf: modelContents)
        }

        let plistData = try PropertyListSerialization.data(fromPropertyList: dataPlist.plist, format: .xml, options: 0)
        let dataFileWrapper = FileWrapper(regularFileWithContents: plistData)
        let contentFileWrapper = self.fileWrapper(forContent: content)

        return (dataFileWrapper, contentFileWrapper)
    }

    private func generateData(for modelType: ModelType) -> ([[ModelPlistKey: Any]], [ModelFile]) {
        var plistItems = [[ModelPlistKey: Any]]()
        var files = [ModelFile]()

        //We'll sort the items so we get a somewhat deterministic ordering on disk
        let sortedItems = self.modelController.anyCollection(for: modelType).all.sorted { $0.id.uuid.uuidString < $1.id.uuid.uuidString }
        sortedItems.forEach { (object) in
            var plist = object.plistRepresentation

            for (plistKey, conversion) in object.propertyConversions {
                guard let value = plist[plistKey] else {
                    continue
                }
                if let (convertedValue, convertedFiles) = self.apply(conversion, toValue: value) {
                    plist[plistKey] = convertedValue
                    files.append(contentsOf: convertedFiles)
                }
            }
            plistItems.append(plist)
        }

        return (plistItems, files)
    }

    private func apply(_ conversion: ModelPropertyConversion, toValue value: Any) -> (Any, [ModelFile])? {
        switch conversion {
        case .modelID:
            if let modelID = value as? ModelID {
                return (modelID.stringRepresentation, [])
            }
        case .array(let conversion):
            if let array = value as? [Any] {
                return self.convertFromArray(array, conversion: conversion)
            }
        case .modelFile:
            if let modelFile = value as? ModelFile {
                return (modelFile.plistRepresentation, [modelFile])
            }
        case .dictionary(let conversions):
            if let dictionary = value as? [ModelPlistKey: Any] {
                return self.convertFromDictionary(dictionary, conversions: conversions)
            }
        }
        return nil
    }

    private func convertFromArray(_ array: [Any], conversion: ModelPropertyConversion) -> ([Any], [ModelFile]) {
        var returnArray = [Any]()
        var returnFiles = [ModelFile]()
        for item in array {
            if let (convertedValue, convertedFiles) = self.apply(conversion, toValue: item) {
                returnArray.append(convertedValue)
                returnFiles.append(contentsOf: convertedFiles)
            } else {
                returnArray.append(item)
            }
        }
        return (returnArray, returnFiles)
    }

    private func convertFromDictionary(_ dictionary: [ModelPlistKey: Any], conversions: [ModelPlistKey: ModelPropertyConversion]) -> (Any, [ModelFile]) {
        var returnDictionary = [String: Any]()
        var returnFiles = [ModelFile]()
        for key in dictionary.keys {
            let value = dictionary[key]
            if let conversion = conversions[key], let (convertedValue, files) = self.apply(conversion, toValue: value as Any) {
                returnDictionary[key.rawValue] = convertedValue
                returnFiles.append(contentsOf: files)
            } else {
                returnDictionary[key.rawValue] = value
            }
        }
        return (returnDictionary, returnFiles)
    }

    private func fileWrapper(forContent content: [ModelFile]) -> FileWrapper {
        var contentWrappers = [String: FileWrapper]()
        content.forEach {
            if let data = $0.data, let filename = $0.filename {
                contentWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
        }
        return FileWrapper(directoryWithFileWrappers: contentWrappers)
    }
}
