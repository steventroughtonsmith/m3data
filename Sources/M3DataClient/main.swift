import M3Data
import AppKit
import CoreGraphics

//Initial line count: 886
//Final line count: 333

@Model
final public class Test {
	@Relationship(inverse: \Test2.testObjects) var test2: Test2? {
		didSet {
			print("Hello World")
		}
	}
}

@Model
final public class Test2 {
	var testObjects: Set<Test> {
		self.relationship(for: \.test2)
	}
}
