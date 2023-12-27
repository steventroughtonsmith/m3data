import M3Data
import AppKit
import CoreGraphics

//Initial line count: 886
//Final line count:

@Model
final public class Canvas {
	public enum Theme: String, CaseIterable {
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

	@Attribute public var zoomFactor: CGFloat = 1 {
		didSet {
			if self.zoomFactor > 1 {
				self.zoomFactor = 1
			} else if self.zoomFactor < 0.25 {
				self.zoomFactor = 0.25
			}
		}
	}

	@Attribute public var thumbnail: NSImage?

	///Added 2021.2
	@Attribute public var alwaysShowPageTitles: Bool = false


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


	//MARK: - Plists
	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [.Canvas.thumbnail: .modelFile]
	}

	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties

		plist[.id] = self.id
		plist[.Canvas.title] = self.title
		plist[.Canvas.dateCreated] = self.dateCreated
		plist[.Canvas.dateModified] = self.dateModified
		plist[.Canvas.sortIndex] = self.sortIndex
		plist[.Canvas.theme] = self.theme.rawValue
		plist[.Canvas.zoomFactor] = self.zoomFactor
		plist[.Canvas.alwaysShowPageTitles] = self.alwaysShowPageTitles

		if let thumbnailData = self.thumbnail?.pngData() {
			plist[.Canvas.thumbnail] = ModelFile(type: "thumbnail", filename: "\(self.id.uuid.uuidString)-thumbnail.png", data: thumbnailData, metadata: [:])
		}
		if let viewPort = self.viewPort  {
			plist[.Canvas.viewPort] = NSStringFromRect(viewPort)
		}

		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		let title: String = try plist.requiredAttribute(withKey: .Canvas.title)
		let dateCreated: Date = try plist.requiredAttribute(withKey: .Canvas.dateCreated)
		let dateModified: Date = try plist.requiredAttribute(withKey: .Canvas.dateModified)
		let sortIndex: Int = try plist.requiredAttribute(withKey: .Canvas.sortIndex)

		let rawTheme: String = try plist.requiredAttribute(withKey: .Canvas.theme)
		guard let theme = Theme(rawValue: rawTheme) else {
			throw ModelObjectUpdateErrors.attributeNotFound(ModelPlistKey.Canvas.theme.rawValue)
		}

		self.title = title
		self.dateCreated = dateCreated
		self.dateModified = dateModified
		self.sortIndex = sortIndex
		self.theme = theme

		if let viewPortString: String = plist.attribute(withKey: .Canvas.viewPort) {
			self.viewPort = NSRectFromString(viewPortString)
		} else {
			self.viewPort = nil
		}

		if let thumbnail: ModelFile = plist.attribute(withKey: .Canvas.thumbnail) {
			if let data = thumbnail.data {
				self.thumbnail = NSImage(data: data)
			}
		} else {
			self.thumbnail = nil
		}

		if let zoomFactor: CGFloat = plist.attribute(withKey: .Canvas.zoomFactor) {
			self.zoomFactor = zoomFactor
		} else {
			self.zoomFactor = 1
		}

		if let alwaysShowPageTitles: Bool = plist.attribute(withKey: .Canvas.alwaysShowPageTitles) {
			self.alwaysShowPageTitles = alwaysShowPageTitles
		}

		let plistKeys = ModelPlistKey.Canvas.all
		self.otherProperties = plist.filter { (key, _) -> Bool in
			return plistKeys.contains(key) == false
		}
	}
}


extension ModelPlistKey {
	enum Canvas {
		static let title = ModelPlistKey(rawValue: "title")
		static let dateCreated = ModelPlistKey(rawValue: "dateCreated")
		static let dateModified = ModelPlistKey(rawValue: "dateModified")
		static let sortIndex = ModelPlistKey(rawValue: "sortIndex")
		static let theme = ModelPlistKey(rawValue: "theme")
		static let zoomFactor = ModelPlistKey(rawValue: "zoomFactor")
		static let thumbnail = ModelPlistKey(rawValue: "thumbnail")
		static let viewPort = ModelPlistKey(rawValue: "viewPort")
		static let alwaysShowPageTitles = ModelPlistKey(rawValue: "alwaysShowPageTitles") ///Added 2021.2
		static let closedPageHierarchies = ModelPlistKey(rawValue: "closedPageHierarchies") ///Removed in 2022.2

		static var all: [ModelPlistKey] {
			return [.id, .Canvas.title, .Canvas.dateCreated, .Canvas.dateModified, .Canvas.sortIndex, .Canvas.theme, .Canvas.zoomFactor, .Canvas.thumbnail, .Canvas.viewPort, .Canvas.alwaysShowPageTitles]
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
		self._content = TestPageContent()
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
	@Attribute public var allowsAutoLinking: Bool = true


	//MARK: - Relationships
	public var canvasPages: Set<CanvasPage> {
		return self.relationship(for: \.page)
	}

	// MARK: - Content
	@Attribute public var content: PageContent {
		didSet {
			self.content.page = self
			NotificationCenter.default.post(name: Page.contentChangedNotification, object: self)
		}
	}

	//MARK: - Plists
	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [.Page.content: .modelFile]
	}

	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties
		plist[.id] = self.id.stringRepresentation
		plist[.Page.title] = self.title
		plist[.Page.dateCreated] = self.dateCreated
		plist[.Page.dateModified] = self.dateModified
		plist[.Page.content] = self.content.modelFile
		if let preferredSize = self.userPreferredSize {
			plist[.Page.userPreferredSize] = NSStringFromSize(preferredSize)
		}
		plist[.Page.allowsAutoLinking] = self.allowsAutoLinking

		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		//Get values
		let title: String = try plist.requiredAttribute(withKey: .Page.title)
		let dateCreated: Date = try plist.requiredAttribute(withKey: .Page.dateCreated)
		let dateModified: Date = try plist.requiredAttribute(withKey: .Page.dateModified)

		var userPreferredSize: CGSize? = nil
		if let userPreferredSizeString: String = plist.attribute(withKey: .Page.userPreferredSize) {
			userPreferredSize = NSSizeFromString(userPreferredSizeString)
		}

		let contentModelFile: ModelFile = try plist.requiredAttribute(withKey: .Page.content)
		guard let contentType = PageContentType(rawValue: contentModelFile.type) else {
			throw ModelObjectUpdateErrors.attributeNotFound(ModelPlistKey.Page.content.rawValue)
		}

		let allowsAutoLinking = plist.attribute(withKey: .Page.allowsAutoLinking) ?? true

		//Set values
		self.title = title
		self.dateCreated = dateCreated
		self.dateModified = dateModified
		self.userPreferredSize = userPreferredSize
		self.content = try contentType.createContent(modelFile: contentModelFile)
		self.allowsAutoLinking = allowsAutoLinking

		let plistKeys = ModelPlistKey.Page.all
		self.otherProperties = plist.filter { (key, _) -> Bool in
			return plistKeys.contains(key) == false
		}
	}
}

extension ModelPlistKey {
	enum Page {
		static let title = ModelPlistKey(rawValue: "title")
		static let dateCreated = ModelPlistKey(rawValue: "dateCreated")
		static let dateModified = ModelPlistKey(rawValue: "dateModified")
		static let content = ModelPlistKey(rawValue: "content")
		static let userPreferredSize = ModelPlistKey(rawValue: "userPreferredSize")
		static let allowsAutoLinking = ModelPlistKey(rawValue: "allowsAutoLinking") //Added 2021.2

		static var all: [ModelPlistKey] {
			return [.id, .Page.title, .Page.dateCreated, .Page.dateModified, .Page.content, .Page.userPreferredSize, .Page.allowsAutoLinking]
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

	//MARK: - Old Relationships
	@ModelObjectReference public var parent: CanvasPage? {
		didSet {
//			self.willChangeValue(for: \.title)
			self.didChangeRelationship(\.parent, inverseKeyPath: \.children, oldValue: oldValue)
//			self.didChangeValue(for: \.title)
		}
	}

	public var children: Set<CanvasPage> {
		self.relationship(for: \.parent)
	}

	//MARK: - Relationship Setup
	public func objectWasInserted() {
		self.$parent.modelController = self.modelController
	}

	public func objectWasDeleted() {
		self.$parent.performCleanUp()
	}


	//MARK: - Plists
	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [
			.CanvasPage.page: .modelID,
			.CanvasPage.canvas: .modelID,
		]
	}

	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties

		plist[.id] = self.id
		plist[.CanvasPage.frame] = NSStringFromRect(self.frame)
		plist[.CanvasPage.zIndex] = self.zIndex

		if let page = self.page {
			plist[.CanvasPage.page] = page.id
		}
		if let canvas = self.canvas {
			plist[.CanvasPage.canvas] = canvas.id
		}
		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard let modelController = self.modelController else {
			throw ModelObjectUpdateErrors.modelControllerNotSet
		}

		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		let frameString: String = try plist.requiredAttribute(withKey: .CanvasPage.frame)
		self.frame = NSRectFromString(frameString)

		if let pageID: ModelID = plist.attribute(withKey: .CanvasPage.page) {
			self.page = modelController.collection(for: Page.self).objectWithID(pageID)
		}

		if let canvasID: ModelID = plist.attribute(withKey: .CanvasPage.canvas) {
			self.canvas = modelController.collection(for: Canvas.self).objectWithID(canvasID)
		}

		if let zIndex: Int = plist.attribute(withKey: .CanvasPage.zIndex) {
			self.zIndex = zIndex
		}

		let plistKeys = ModelPlistKey.CanvasPage.all
		self.otherProperties = plist.filter { (key, _) -> Bool in
			return plistKeys.contains(key) == false
		}
	}
}

extension ModelPlistKey {
	enum CanvasPage {
		static let frame = ModelPlistKey(rawValue: "frame")
		static let zIndex = ModelPlistKey(rawValue: "zIndex")
		static let page = ModelPlistKey(rawValue: "page")
		static let canvas = ModelPlistKey(rawValue: "canvas")
		static let parent = ModelPlistKey(rawValue: "parent")

		static var all: [ModelPlistKey] {
			return [.id, .CanvasPage.frame, .CanvasPage.zIndex, .CanvasPage.page, .CanvasPage.canvas, .CanvasPage.parent]
		}
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

	//MARK: - Plist
	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [
			.CanvasLink.sourcePage: .modelID,
			.CanvasLink.destinationPage: .modelID,
			.CanvasLink.canvas: .modelID,
		]
	}

	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties
		plist[.id] = self.id

		if let link = self.link {
			plist[.CanvasLink.link] = link.url.absoluteString
		}

		if let destinationPage = self.destinationPage {
			plist[.CanvasLink.destinationPage] = destinationPage.id
		}

		if let sourcePage = self.sourcePage {
			plist[.CanvasLink.sourcePage] = sourcePage.id
		}

		if let canvas = self.canvas {
			plist[.CanvasLink.canvas] = canvas.id
		}

		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		if let linkString: String = plist.attribute(withKey: .CanvasLink.link), let linkURL = URL(string: linkString), let link = PageLink(url: linkURL) {
			self.link = link
		}

		if let destinationID: ModelID = plist.attribute(withKey: .CanvasLink.destinationPage) {
//			self.$destinationPage.modelID = destinationID
		}

		if let sourceID: ModelID = plist.attribute(withKey: .CanvasLink.sourcePage) {
//			self.$sourcePage.modelID = sourceID
		}

		if let canvasID: ModelID = plist.attribute(withKey: .CanvasLink.canvas) {
//			self.$canvas.modelID = canvasID
		}

		let plistKeys = ModelPlistKey.CanvasLink.all
		self.otherProperties = plist.filter { (key, _) -> Bool in
			return plistKeys.contains(key) == false
		}
	}
}


extension ModelPlistKey {
	enum CanvasLink {
		static let link = ModelPlistKey(rawValue: "link")
		static let destinationPage = ModelPlistKey(rawValue: "destinationPage")
		static let sourcePage = ModelPlistKey(rawValue: "sourcePage")
		static let canvas = ModelPlistKey(rawValue: "canvas")

		static var all: [ModelPlistKey] {
			return [.id, .CanvasLink.link, .CanvasLink.destinationPage, .CanvasLink.sourcePage, .CanvasLink.canvas]
		}
	}
}


@Model
final public class PageHierarchy {
	//MARK: - Attributes
	@Attribute public var rootPageID: ModelID?
	@Attribute public var entryPoints: [EntryPoint] = []
	@Attribute public var pages: [PageRef] = []
	@Attribute public var links: [LinkRef] = []

	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [
			.PageHierarchy.rootPageID: .modelID,
			.PageHierarchy.pages: .array(.dictionary([
				.PageHierarchy.PageRef.canvasPageID: .modelID,
				.PageHierarchy.PageRef.pageID: .modelID,
			])),
			.PageHierarchy.links: .array(.dictionary([
				.PageHierarchy.LinkRef.sourceID: .modelID,
				.PageHierarchy.LinkRef.destinationID: .modelID,
			])),
			.PageHierarchy.entryPoints: .array(.dictionary([:])),
			.PageHierarchy.canvas: .modelID,
		]
	}

	//MARK: - Relationships
	@Relationship(inverse: \Canvas.pageHierarchies) public var canvas: Canvas?


	//MARK: - Plist
	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties
		plist[.id] = self.id
		plist[.PageHierarchy.rootPageID] = self.rootPageID
		plist[.PageHierarchy.entryPoints] = self.entryPoints.map(\.plistRepresentation)
		plist[.PageHierarchy.pages] = self.pages.map(\.plistRepresentation)
		plist[.PageHierarchy.links] = self.links.map(\.plistRepresentation)
		plist[.PageHierarchy.canvas] = self.canvas?.id.stringRepresentation
		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard let modelController = self.modelController else {
			throw ModelObjectUpdateErrors.modelControllerNotSet
		}

		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		let rootPageID: ModelID? = plist.attribute(withKey: .PageHierarchy.rootPageID)
		let rawEntryPoints: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHierarchy.entryPoints)
		let rawPages: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHierarchy.pages)
		let rawLinks: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHierarchy.links)

		var entryPoints: [EntryPoint] = []
		for rawEntryPoint in rawEntryPoints {
			guard let entryPoint = EntryPoint(plist: rawEntryPoint) else {
				throw ModelObjectUpdateErrors.attributeNotFound("entryPoints")
			}
			entryPoints.append(entryPoint)
		}

		var pages: [PageRef] = []
		for rawPage in rawPages {
			guard let pageRef = PageRef(plist: rawPage) else {
				throw ModelObjectUpdateErrors.attributeNotFound("pages")
			}
			pages.append(pageRef)
		}

		var links: [LinkRef] = []
		for rawLink in rawLinks {
			guard let link = LinkRef(plist: rawLink) else {
				throw ModelObjectUpdateErrors.attributeNotFound("links")
			}
			links.append(link)
		}

		self.rootPageID = rootPageID
		self.entryPoints = entryPoints
		self.pages = pages
		self.links = links

		if let canvasID: ModelID = plist.attribute(withKey: .PageHierarchy.canvas) {
			self.canvas = modelController.collection(for: Canvas.self).objectWithID(canvasID)
		}
	}

	//MARK: - Relationship Setup
	public func objectWasInserted() {
		self.$canvas.modelController = self.modelController
	}

	public func objectWasDeleted() {
		self.$canvas.performCleanUp()
	}
}

extension PageHierarchy {
	public struct EntryPoint {
		var pageLink: PageLink
		var relativePosition: CGPoint

		init(pageLink: PageLink, relativePosition: CGPoint) {
			self.pageLink = pageLink
			self.relativePosition = relativePosition
		}

		init?(plist: [ModelPlistKey: Any]) {
			guard
				let pageLinkString: String = try? plist.requiredAttribute(withKey: .PageHierarchy.EntryPoint.pageLink),
				let url = URL(string: pageLinkString),
				let pageLink = PageLink(url: url),
				let relativePositionString: String = try? plist.requiredAttribute(withKey: .PageHierarchy.EntryPoint.relativePosition)
			else {
				return nil
			}

			self.pageLink = pageLink
			self.relativePosition = NSPointFromString(relativePositionString)
		}

		var plistRepresentation: [ModelPlistKey: Any] {
			return [
				.PageHierarchy.EntryPoint.pageLink: self.pageLink.url.absoluteString,
				.PageHierarchy.EntryPoint.relativePosition: NSStringFromPoint(self.relativePosition),
			]
		}
	}

	public struct PageRef {
		var canvasPageID: ModelID
		var pageID: ModelID
		/// Position relative to the hierarchy
		var relativeContentFrame: CGRect

		internal init(canvasPageID: ModelID, pageID: ModelID, relativeContentFrame: CGRect) {
			self.canvasPageID = canvasPageID
			self.pageID = pageID
			self.relativeContentFrame = relativeContentFrame
		}


		init?(plist: [ModelPlistKey: Any]) {
			guard
				let canvasPageID: ModelID = try? plist.requiredAttribute(withKey: .PageHierarchy.PageRef.canvasPageID),
				let pageID: ModelID = try? plist.requiredAttribute(withKey: .PageHierarchy.PageRef.pageID),
				let relativeFrameString: String = try? plist.requiredAttribute(withKey: .PageHierarchy.PageRef.relativeContentFrame)
			else {
				return nil
			}

			self.canvasPageID = canvasPageID
			self.pageID = pageID
			self.relativeContentFrame = NSRectFromString(relativeFrameString)
		}

		var plistRepresentation: [ModelPlistKey: Any] {
			return [
				.PageHierarchy.PageRef.canvasPageID: self.canvasPageID,
				.PageHierarchy.PageRef.pageID: self.pageID,
				.PageHierarchy.PageRef.relativeContentFrame: NSStringFromRect(self.relativeContentFrame),
			]
		}
	}

	public struct LinkRef {
		var sourceID: ModelID
		var destinationID: ModelID
		var link: PageLink

		init(sourceID: ModelID, destinationID: ModelID, link: PageLink) {
			self.sourceID = sourceID
			self.destinationID = destinationID
			self.link = link
		}

		init?(plist: [ModelPlistKey: Any]) {
			guard
				let sourceID: ModelID = try? plist.requiredAttribute(withKey: .PageHierarchy.LinkRef.sourceID),
				let destinationID: ModelID = try? plist.requiredAttribute(withKey: .PageHierarchy.LinkRef.destinationID),
				let linkString: String = try? plist.requiredAttribute(withKey: .PageHierarchy.LinkRef.link),
				let url = URL(string: linkString),
				let pageLink = PageLink(url: url)
			else {
				return nil
			}

			self.sourceID = sourceID
			self.destinationID = destinationID
			self.link = pageLink
		}

		var plistRepresentation: [ModelPlistKey: Any] {
			return [
				.PageHierarchy.LinkRef.sourceID: self.sourceID,
				.PageHierarchy.LinkRef.destinationID: self.destinationID,
				.PageHierarchy.LinkRef.link: self.link.url.absoluteString,
			]
		}
	}
}

extension ModelPlistKey {
	enum PageHierarchy {
		static let rootPageID = ModelPlistKey(rawValue: "rootPageID")
		static let entryPoints = ModelPlistKey(rawValue: "entryPoints")
		static let pages = ModelPlistKey(rawValue: "pages")
		static let links = ModelPlistKey(rawValue: "links")
		static let canvas = ModelPlistKey(rawValue: "canvas")

		enum EntryPoint {
			static let pageLink = ModelPlistKey(rawValue: "pageLink")
			static let relativePosition = ModelPlistKey(rawValue: "relativePosition")
		}

		enum PageRef {
			static let canvasPageID = ModelPlistKey(rawValue: "canvasPageID")
			static let pageID = ModelPlistKey(rawValue: "pageID")
			static let relativeContentFrame = ModelPlistKey(rawValue: "relativeContentFrame")
		}

		enum LinkRef {
			static let sourceID = ModelPlistKey(rawValue: "sourceID")
			static let destinationID = ModelPlistKey(rawValue: "destinationID")
			static let link = ModelPlistKey(rawValue: "link")
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


	//MARK: - Plist
	public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
		return [.Folder.contents: .array(.modelID)]
	}

	public var plistRepresentation: [ModelPlistKey: Any] {
		var plist = self.otherProperties

		plist[.id] = self.id
		plist[.Folder.title] = self.title
		plist[.Folder.contents] = self.contents.map(\.id)
		plist[.Folder.dateCreated] = self.dateCreated

		return plist
	}

	public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
		guard self.id == plist.attribute(withKey: .id) else {
			throw ModelObjectUpdateErrors.idsDontMatch
		}

		let title: String = try plist.requiredAttribute(withKey: .Folder.title)
		let dateCreated: Date = try plist.requiredAttribute(withKey: .Folder.dateCreated)

		let contentsIDs: [ModelID] = try plist.requiredAttribute(withKey: .Folder.contents)
		let contents = contentsIDs.compactMap { self.modelController?.object(with: $0) as? FolderContainable }
		guard contentsIDs.count == contents.count else {
			throw ModelObjectUpdateErrors.attributeNotFound(ModelPlistKey.Folder.contents.rawValue)
		}
		contents.forEach { $0.containingFolder = self }

		self.title = title
		self.dateCreated = dateCreated
		self.contents = contents

		let plistKeys = ModelPlistKey.Folder.all
		self.otherProperties = plist.filter { (key, _) -> Bool in
			return plistKeys.contains(key) == false
		}
	}
}


extension ModelPlistKey {
	enum Folder {
		static let title = ModelPlistKey(rawValue: "title")
		static let dateCreated = ModelPlistKey(rawValue: "dateCreated")
		static let contents = ModelPlistKey(rawValue: "contents")

		static var all: [ModelPlistKey] {
			return [.id, .Folder.title, .Folder.dateCreated, .Folder.contents]
		}
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

extension NSImage {
	func pngData() -> Data? {
		return nil
	}
}


public protocol PageContent {
	var page: Page? { get set }
	var initialContentSize: CGSize? { get }
	var modelFile: ModelFile { get }
}

enum PageContentType: String {
	case text
	case image

	func createContent(modelFile: ModelFile) throws -> PageContent {
		throw NSError(domain: "Test", code: -1)
	}
}

class TestPageContent: PageContent {
	var page: Page?
	var initialContentSize: CGSize?
	var modelFile: ModelFile {
		return ModelFile(type: "", filename: nil, data: nil, metadata: nil)
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
