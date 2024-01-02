//
//  ModelID+Pasteboard.swift
//  M3Data
//
//  Created by Martin Pilkington on 18/05/2022.
//

import AppKit

//MARK: - Pasteboard Item Conversion
extension ModelID {
	private static let UUIDKey = "uuid"
	private static let modelTypeKey = "modelType"

	public static let PasteboardType = NSPasteboard.PasteboardType("com.mcubedsw.Coppice.modelID")
	public var pasteboardItem: NSPasteboardItem {
		let pasteboardItem = NSPasteboardItem()
		pasteboardItem.setPropertyList(self.plistRepresentation, forType: ModelID.PasteboardType)
		return pasteboardItem
	}

	public var plistRepresentation: Any {
		return [ModelID.UUIDKey: self.uuid.uuidString, ModelID.modelTypeKey: self.modelType.rawValue]
	}

	public init?(pasteboardItem: NSPasteboardItem) {
		guard pasteboardItem.types.contains(ModelID.PasteboardType),
			  let propertyList = pasteboardItem.propertyList(forType: ModelID.PasteboardType) as? [String: String],
			  let uuidString = propertyList[ModelID.UUIDKey],
			  let modelTypeString = propertyList[ModelID.modelTypeKey]
		else {
			return nil
		}
		self.init(modelType: ModelType(rawValue: modelTypeString), uuidString: uuidString)
	}
}


//MARK: - Pasteboard Helper
extension NSPasteboard {
	public var modelIDs: [ModelID] {
		guard
			self.types?.contains(ModelID.PasteboardType) == true,
			let pasteboardItems = self.pasteboardItems
		else {
			return []
		}

		return pasteboardItems.compactMap { ModelID(pasteboardItem: $0) }
	}
}
