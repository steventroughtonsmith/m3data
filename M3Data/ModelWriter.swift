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
            let plist = object.plistRepresentation.mapValues { (value) -> Any in
                guard let file = value as? ModelFile else {
                    return value
                }

                files.append(file)
                return file.plistRepresentation
            }
            plistItems.append(plist)
        }

        return (plistItems, files)
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
