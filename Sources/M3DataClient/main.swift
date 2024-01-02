import M3Data
import AppKit
import CoreGraphics

//Initial line count: 886
//Final line count: 333

@Model
final public class Canvas {
	public enum Theme: String, CaseIterable, PlistConvertable {
		case auto
		case dark
		case light

		public var localizedName: String {
			switch self {
			case .auto: return NSLocalizedString("Automatic", comment: "Automatic theme name")
			case .dark: return NSLocalizedString("Dark", comment: "Dark theme name")
			case .light: return NSLocalizedString("Light", comment: "Light theme name")
			}
		}

		public func toPlistValue() throws -> PlistValue {
			return self.rawValue
		}

		public static func fromPlistValue(_ plistValue: PlistValue) throws -> Theme {
			guard
				let value = plistValue as? String,
				let theme = Theme(rawValue: value)
			else {
				throw PlistConvertableError.invalidConversionFromPlistValue
			}
			return theme
		}
	}

	public func objectWasInserted() {
		self.sortIndex = self.collection?.all.count ?? 0
	}

	//MARK: - Attributes
	@Attribute public var title: String = "New Canvas"

	@Attribute public var dateCreated = Date()
	@Attribute public var dateModified = Date()
	@Attribute public var sortIndex = 0

	@Attribute public var theme: Theme = .auto

	@Attribute public var viewPort: CGRect?

	@Attribute(optional: true, default: 1) public var zoomFactor: Double = 1 {
		didSet {
			if self.zoomFactor > 1 {
				self.zoomFactor = 1
			} else if self.zoomFactor < 0.25 {
				self.zoomFactor = 0.25
			}
		}
	}

	@Attribute(optional: true, isModelFile: true) public var thumbnail: Thumbnail?

	///Added 2021.2
	@Attribute(optional: true, default: false) public var alwaysShowPageTitles: Bool = false


	//MARK: - Relationships
	public var pages: Set<CanvasPage> {
		return self.relationship(for: \.canvas)
	}

	public var links: Set<CanvasLink> {
		return self.relationship(for: \.canvas)
	}

	public var pageHierarchies: Set<PageHierarchy> {
		return self.relationship(for: \.canvas)
	}
}

extension Canvas {
	public struct Thumbnail: PlistConvertable {
		public let data: Data
		public let canvasID: ModelID

		public func toPlistValue() throws -> PlistValue {
			return ModelFile(type: "thumbnail", filename: "\(canvasID.uuid.uuidString)-thumbnail.png", data: data, metadata: [:])
		}

		public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
			guard
				let modelFile: ModelFile = try .fromPlistValue(plistValue),
				let thumbnailComponents = modelFile.filename?.components(separatedBy: "-thumbnail"),
				thumbnailComponents.count == 2,
				let uuid = UUID(uuidString: thumbnailComponents[0]),
				let data = modelFile.data
			else {
				throw PlistConvertableError.invalidConversionFromPlistValue
			}
			return self.init(data: data, canvasID: Canvas.modelID(with: uuid))
		}
	}
}

@Model
final public class Page {
	public static let standardSize = CGSize(width: 300, height: 200)
	public static let defaultMinimumContentSize = CGSize(width: 150, height: 100)
	public static let contentChangedNotification = Notification.Name("PageContentChangedNotification")
	public static let localizedDefaultTitle = "Untitled Page"


	//MARK: - Init
	public init() {
		self._title = ""
		self._content = PageContent()
		self.content.page = self
	}


	// MARK: - Attributes
	@Attribute public var title: String

	@Attribute public var dateCreated = Date()
	@Attribute public var dateModified = Date()
	@Attribute private var userPreferredSize: CGSize?
	public var contentSize: CGSize {
		get {
			return self.userPreferredSize ?? self.content.initialContentSize ?? Page.standardSize
		}
		set {
			self.userPreferredSize = newValue
		}
	}

	/// Added in 2021.2
	@Attribute(optional: true, default: true) public var allowsAutoLinking: Bool = true


	//MARK: - Relationships
	public var canvasPages: Set<CanvasPage> {
		return self.relationship(for: \.page)
	}

	// MARK: - Content
	@Attribute(isModelFile: true) public var content: PageContent {
		didSet {
			self.content.page = self
			NotificationCenter.default.post(name: Page.contentChangedNotification, object: self)
		}
	}
}

@Model
final public class CanvasPage {
	//MARK: - Attributes
	@Attribute public var frame: CGRect = .zero
	@Attribute public var zIndex: Int = -1


	//MARK: - Relationships
	@Relationship(inverse: \Page.canvasPages) public var page: Page? {
		didSet {
			if let page = self.page, self.frame.size == .zero {
				self.frame.size = page.contentSize
			}
			//TODO: Update title
		}
	}

	@Relationship(inverse: \Canvas.pages) public var canvas: Canvas?

	public var linksOut: Set<CanvasLink> {
		return self.relationship(for: \.sourcePage)
	}

	public var linksIn: Set<CanvasLink> {
		return self.relationship(for: \.destinationPage)
	}
}


@Model
final public class CanvasLink {
	//MARK: - Properties
	@Attribute public var link: PageLink?

	//MARK: - Relationships
	@Relationship(inverse: \CanvasPage.linksIn) public var destinationPage: CanvasPage?
	@Relationship(inverse: \CanvasPage.linksOut) public var sourcePage: CanvasPage?
	@Relationship(inverse: \Canvas.links) public var canvas: Canvas?
}


@Model
final public class PageHierarchy {
	//MARK: - Attributes
	@Attribute public var rootPageID: ModelID?
	@Attribute public var entryPoints: [EntryPoint] = []
	@Attribute public var pages: [PageRef] = []
	@Attribute public var links: [LinkRef] = []

	//MARK: - Relationships
	@Relationship(inverse: \Canvas.pageHierarchies) public var canvas: Canvas?
}

extension PageHierarchy {
	public struct EntryPoint: PlistConvertable {
		var pageLink: PageLink
		var relativePosition: CGPoint

		init(pageLink: PageLink, relativePosition: CGPoint) {
			self.pageLink = pageLink
			self.relativePosition = relativePosition
		}

		public func toPlistValue() throws -> PlistValue {
			return [
				"pageLink": try self.pageLink.toPlistValue(),
				"relativePosition": try self.relativePosition.toPlistValue()
			] as PlistValue
		}

		public static func fromPlistValue(_ plistValue: PlistValue) throws -> PageHierarchy.EntryPoint {
			guard 
				let value = plistValue as? [String: PlistValue],
				let pageLink = value["pageLink"],
				let relativePosition = value["relativePosition"]
			else {
				throw PlistConvertableError.invalidConversionFromPlistValue
			}
			return EntryPoint(pageLink: try .fromPlistValue(pageLink),
							  relativePosition: try .fromPlistValue(relativePosition))
		}
	}

	public struct PageRef: PlistConvertable {
		var canvasPageID: ModelID
		var pageID: ModelID
		/// Position relative to the hierarchy
		var relativeContentFrame: CGRect

		internal init(canvasPageID: ModelID, pageID: ModelID, relativeContentFrame: CGRect) {
			self.canvasPageID = canvasPageID
			self.pageID = pageID
			self.relativeContentFrame = relativeContentFrame
		}

		public func toPlistValue() throws -> PlistValue {
			return [
				"canvasPageID": try self.canvasPageID.toPlistValue(),
				"pageID": try self.pageID.toPlistValue(),
				"relativeContentFrame": try self.relativeContentFrame.toPlistValue()
			] as PlistValue
		}

		public static func fromPlistValue(_ plistValue: PlistValue) throws -> PageRef {
			guard
				let value = plistValue as? [String: PlistValue],
				let canvasPageID = value["canvasPageID"],
				let pageID = value["pageID"],
				let relativeContentFrame = value["relativeContentFrame"]
			else {
				throw PlistConvertableError.invalidConversionFromPlistValue
			}
			return PageRef(canvasPageID: try .fromPlistValue(canvasPageID),
						   pageID: try .fromPlistValue(pageID),
						   relativeContentFrame: try .fromPlistValue(relativeContentFrame))
		}
	}

	public struct LinkRef: PlistConvertable {
		var sourceID: ModelID
		var destinationID: ModelID
		var link: PageLink

		init(sourceID: ModelID, destinationID: ModelID, link: PageLink) {
			self.sourceID = sourceID
			self.destinationID = destinationID
			self.link = link
		}

		public func toPlistValue() throws -> PlistValue {
			return [
				"sourceID": try self.sourceID.toPlistValue(),
				"destinationID": try self.destinationID.toPlistValue(),
				"link": try self.link.toPlistValue()
			] as PlistValue
		}

		public static func fromPlistValue(_ plistValue: PlistValue) throws -> LinkRef {
			guard
				let value = plistValue as? [String: PlistValue],
				let sourceID = value["sourceID"],
				let destinationID = value["destinationID"],
				let link = value["link"]
			else {
				throw PlistConvertableError.invalidConversionFromPlistValue
			}
			return LinkRef(sourceID: try .fromPlistValue(sourceID),
						   destinationID: try .fromPlistValue(destinationID),
						   link: try .fromPlistValue(link))
		}
	}
}


@Model
final public class Folder: FolderContainable {
	public static let rootFolderTitle = "__ROOT__FOLDER__"


	//MARK: - Persisted Attributes
	@Attribute public var title: String = "New Folder"
	@Attribute public var dateCreated: Date = Date()

	public var dateModified: Date {
		guard self.contents.count > 0 else {
			return self.dateCreated
		}

		let sorted = self.contents.sorted(by: { $0.dateModified > $1.dateModified })
		return sorted[0].dateModified
	}

	@Attribute public weak var containingFolder: Folder?

	@Attribute public var contents: [FolderContainable] = []

	public var sortType: String {
		return "0Folder"
	}
}





//MARK: - Not model objects

public struct PageLink: Equatable, Hashable {
	public static let host = "page"
	public static let querySourceName = "source"
	public static let queryAutoName = "auto"
	public let destination: ModelID
	public let source: ModelID?
	public let autoGenerated: Bool

	public init(destinationPage: Page, sourceCanvasPage: CanvasPage? = nil, autoGenerated: Bool = false) {
		self.init(destination: destinationPage.id, source: sourceCanvasPage?.id, autoGenerated: autoGenerated)
	}

	public init(destination: ModelID, source: ModelID? = nil, autoGenerated: Bool = false) {
		self.destination = destination
		self.source = source
		self.autoGenerated = autoGenerated
	}

	public init?(url: URL) {
		guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
			  urlComponents.scheme == "coppice",
			  urlComponents.host == PageLink.host
		else {
			return nil
		}

		let path = urlComponents.path
		let destinationUUIDString = String(path[(path.index(after: path.startIndex))...])
		guard let destinationID = Page.modelID(withUUIDString: destinationUUIDString) else {
			return nil
		}

		var sourceID: ModelID? = nil
		var autoGenerated = false

		self.init(destination: destinationID, source: sourceID, autoGenerated: autoGenerated)
	}

	public var url: URL {
		var urlComponents = URLComponents()
		urlComponents.scheme = "coppice"
		urlComponents.host = PageLink.host
		urlComponents.path = "/\(self.destination.uuid.uuidString)"
		var queryItems = [URLQueryItem]()
		if let source = self.source {
			queryItems.append(URLQueryItem(name: PageLink.querySourceName, value: source.uuid.uuidString))
		}
		if self.autoGenerated {
			queryItems.append(URLQueryItem(name: PageLink.queryAutoName, value: "1"))
		}
		if queryItems.count > 0 {
			urlComponents.queryItems = queryItems
		}
		guard let url = urlComponents.url else {
			preconditionFailure("Failed to create url from components: \(urlComponents)")
		}
		return url
	}

	public func withSource(_ source: ModelID? = nil) -> Self {
		return PageLink(destination: self.destination, source: source, autoGenerated: self.autoGenerated)
	}

	public static func == (lhs: PageLink, rhs: PageLink) -> Bool {
		return lhs.destination == rhs.destination && lhs.source == rhs.source
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.destination)
		hasher.combine(self.source)
	}
}

extension PageLink: PlistConvertable {
	public func toPlistValue() throws -> PlistValue {
		return self.url.absoluteString
	}
	
	public static func fromPlistValue(_ plistValue: PlistValue) throws -> PageLink {
		let url: URL = try .fromPlistValue(plistValue)
		guard let pageLink = PageLink(url: url) else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}
		return pageLink
	}
	

}

extension NSImage {
	func pngData() -> Data? {
		return nil
	}
}


public class PageContent: PlistConvertable {
	weak var page: Page?
	var initialContentSize: CGSize? {
		return nil
	}
	var modelFile: ModelFile {
		return ModelFile(type: "", filename: nil, data: nil, metadata: nil)
	}
}

extension PageContent {
	public func toPlistValue() throws -> PlistValue {
		return self.modelFile
	}

	public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
		guard
			let modelFile = plistValue as? ModelFile,
			let contentType = PageContentType(rawValue: modelFile.type),
			let content = try contentType.createContent(modelFile: modelFile) as? Self
		else {
			throw PlistConvertableError.invalidConversionFromPlistValue
		}

		return content
	}
}

enum PageContentType: String {
	case text
	case image

	func createContent(modelFile: ModelFile) throws -> PageContent {
		throw NSError(domain: "Test", code: -1)
	}
}

/// An object that can be contained in a folder
public protocol FolderContainable: ModelObject {
	var containingFolder: Folder? { get set }
	var dateCreated: Date { get }
	var dateModified: Date { get }
	var title: String { get }
	var sortType: String { get }

	func removeFromContainingFolder()
}

extension FolderContainable {
	public func removeFromContainingFolder() {
	}
}
