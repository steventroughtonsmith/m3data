import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct M3DataMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelMacro.self,
		AttributeMacro.self,
		RelationshipMacro.self,
		Relationship2Macro.self,
    ]
}
