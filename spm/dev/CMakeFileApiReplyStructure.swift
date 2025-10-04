
struct Index: Codable {
    let reply: IndexReply
}

struct IndexReply: Codable {
    let codemodel: IndexObject
    let toolchains: IndexObject
    enum CodingKeys: String, CodingKey {
        case codemodel = "codemodel-v2"
        case toolchains = "toolchains-v1"
    }
}

struct IndexObject: Codable {
    let jsonFile: String
    let kind: IndexObjectKind
    let version: IndexObjectVersion
}

enum IndexObjectKind: String, Codable {
    case codemodel = "codemodel"
    case toolchains = "toolchains"
}

struct IndexObjectVersion: Codable {
    let major: Int
    let minor: Int
}

struct Codemodel: Codable {
    let configurations: [CodemodelConfiguration]
    let paths: CodemodelPaths
}

struct CodemodelConfiguration: Codable {
    let name: String
    let directories: [CodemodelDirectory]
    let projects: [CodemodelProject]
    let targets: [CodemodelTarget]
}

struct CodemodelDirectory: Codable {
    let build: String
    let source: String
    let hasInstallRule: Bool
    let jsonFile: String
}

struct CodemodelProject: Codable {
    let directoryIndexes: [Int]
    let name: String
    let targetIndexes: [Int]
}

struct CodemodelTarget: Codable {
    let directoryIndex: Int
    let id: String
    let jsonFile: String
    let name: String
    let projectIndex: Int
}

struct CodemodelPaths: Codable {
    let source: String
    let build: String
}

struct Toolchains: Codable {
}

struct Target: Codable {
    let sources: [TargetSource]
    let sourceGroups: [TargetSourceGroup]
    let compileGroups: [TargetCompileGroup]
    let type: String
    let link: TargetLink
}

struct TargetSource: Codable {
    let backtrace: Int
    let compileGroupIndex: Int
    let path: String
    let sourceGroupIndex: Int
}

struct TargetSourceGroup: Codable {
    let name: String
    let sourceIndexes: [Int]
}

struct TargetCompileFragment: Codable {
    let backtrace: Int?
    let fragment: String
}

struct TargetDefine: Codable {
    let define: String
}

struct TargetInclude: Codable {
    let backtrace: Int?
    let path: String
}

struct TargetCompileGroup: Codable {
    let compileCommandFragments: [TargetCompileFragment]
    let defines: [TargetDefine]
    let includes: [TargetInclude]
    let language: String
    let sourceIndexes: [Int]
}

struct TargetLinkFragment: Codable {
    let backtrace: Int?
    let fragment: String
    let role: String
}

struct TargetLink: Codable {
    let commandFragments: [TargetLinkFragment]
    let language: String
}

struct Directory: Codable {
	let installers: [DirectoryInstaller]
}

struct DirectoryInstaller: Codable {
	let backtrace: Int
	let component: String
	let destination: String
	let paths: [String]
	let targetId: String?
	let targetIndex: Int?
	let type: String
}
