
import Foundation

class CxxSwiftPackage {
    let projectName: String
    let projectUrl: URL
    let package: CxxPackage

    let spmDir: URL
    let srcDir: URL
    let privateIncludeDir: URL
    let publicIncludeDir: URL

    init(projectName: String, projectUrl: URL, package: CxxPackage) {
        self.projectName = projectName
        self.projectUrl = projectUrl
        self.package = package
        self.spmDir = projectUrl.appendingPathComponent("spm", isDirectory: true)
        self.srcDir = spmDir.appendingPathComponent("src", isDirectory: true)
        self.privateIncludeDir = spmDir.appendingPathComponent("inc", isDirectory: true)
        self.publicIncludeDir = spmDir.appendingPathComponent("public", isDirectory: true)
    }

    func clean() {
        removeDirectoryContent(at: srcDir)
        removeDirectoryContent(at: privateIncludeDir)
        removeDirectoryContent(at: publicIncludeDir)
    }

    func build() {
        clean()

        // Copy source files
        for source in package.sources {
            let relativePath = source.relativePath
            let dest = URL(string: relativePath, relativeTo: srcDir)!
            copyFile(source, to: dest)
        }

        // Copy private headers
        let sourceBaseUrl = package.sources.first!.baseURL!
        for header in package.privateIncludes {
            let baseUrl = header.baseURL!
            let relativePath = header.relativePath
            if baseUrl == sourceBaseUrl {
                // If the header is in the same directory as a source file, we can
                // put it in the same relative path in the src directory.
                let dest = URL(string: relativePath, relativeTo: srcDir)!
                copyFile(header, to: dest)
            } else {
                let dest = URL(string: relativePath, relativeTo: privateIncludeDir)!
                copyFile(header, to: dest)
            }
        }

        // Copy public headers
        for header in package.publicIncludes {
            let relativePath = header.relativePath
            let dest = URL(string: relativePath, relativeTo: publicIncludeDir)!
            copyFile(header, to: dest)
        }

        // Generate Package.swift
        let packageDescription = """
            // swift-tools-version: 6.2
            
            import PackageDescription

            let package = Package(
                name: "\(projectName)",
                platforms: [
                    .macOS(.v15),
                ],
                products: [
                    .library(
                        name: "\(projectName)",
                        targets: ["\(projectName)"]),
                    .executable(
                        name: "dev",
                        targets: ["dev"]),
                ],
                dependencies: [],
                targets: [
                    .target(
                        name: "\(projectName)",
                        dependencies: [],
                        path: "spm",
                        sources: ["src"],
                        publicHeadersPath: "public",
                        cSettings: [
                            .headerSearchPath("src"),
                            .headerSearchPath("inc"),
                            .headerSearchPath("public")\(formatCompilerSettings(indent: "                ", flags: package.cFlags, cpp: false))
                        ],
                        cxxSettings: [
                            .headerSearchPath("src"),
                            .headerSearchPath("inc"),
                            .headerSearchPath("public")\(formatCompilerSettings(indent: "                ", flags: package.cppFlags, cpp: true))
                        ],
                        linkerSettings: [\(formatLinkerSettings(flags: package.linkFlags, separator: "\n                "))
                        ]
                    ),
                    .executableTarget(
                        name: "dev",
                        path: "spm/dev",
                    ),
                ]\(formatLanguageStandards(indent: "    ", flags: package.cFlags + package.cppFlags))
            )
            """

        let packageDescriptionFile = projectUrl.appendingPathComponent("Package.swift")
        try? FileManager.default.removeItem(at: packageDescriptionFile)
        try! packageDescription.write(to: packageDescriptionFile, atomically: true, encoding: .utf8)
    }

    private func copyFile(_ source: URL, to dest: URL) {
        precondition(!source.hasDirectoryPath)
        precondition(!dest.hasDirectoryPath)
        let destFolder = dest.deletingLastPathComponent()
        try! FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: dest)
        try! FileManager.default.copyItem(at: source, to: dest)
    }

    private func formatCompilerSettings(indent: String, flags: [String], cpp: Bool) -> String {
        var ret: String = ""
        for flag in flags {
            if let _ = flag.firstMatch(of: /^-std=(.+)/) {
                // ignore this setting, as it is handled elsewhere
            } else if let match = flag.firstMatch(of: /^-I(.+)/) {
                let path = String(match.1)
                print("Warning: Ignoring header search path \(path)")
            } else if flag == "-DNDEBUG" {
                ret.append(",\n\(indent).define(\"NDEBUG\", .when(configuration: .release))")
            } else if let match = flag.firstMatch(of: /^-D(.+)=(.+)/) {
                let define = String(match.1)
                let value: String = String(match.2)
                ret.append(",\n\(indent).define(\"\(define)\", to: \"\(value)\")")
            } else if let match = flag.firstMatch(of: /^-D(.+)/) {
                let define = String(match.1)
                ret.append(",\n\(indent).define(\"\(define)\")")
            } else {
                print("Warning: Ignoring \(cpp ? "C++" : "C") flag \(flag)")
            }
        }
        return ret
    }

    private func extractLanguageStandards(flags: [String]) -> [String] {
        var standards: [String] = []
        for flag in flags {
            if let match = flag.firstMatch(of: /^-std=(.+)/) {
                let standard = String(match.1)
                standards.append(standard)
            }
        }
        return standards
    }

    private func formatLanguageStandards(indent: String, flags: [String]) -> String {
        var ret = ""
        let standards = extractLanguageStandards(flags: flags)
        var cStandard: String? = nil
        var cxxStandard: String? = nil
        for standard in standards {
            if standard.range(of: "++") != nil {
                if cxxStandard != nil && cxxStandard != standard {
                    fatalError("Warning: Multiple C++ standards found: \(cxxStandard!), \(standard)")
                }
                cxxStandard = standard
            } else {
                if cStandard != nil && cStandard != standard {
                    fatalError("Warning: Multiple C standards found: \(cStandard!), \(standard)")
                }
                cStandard = standard
            }
        }
        if let cStandard {
            ret.append(",\n\(indent)cLanguageStandard: .\(cStandard)")
        }
        if let cxxStandard {
            ret.append(",\n\(indent)cxxLanguageStandard: .\(cxxStandard.replacing("++", with: "xx"))")
        }
        return ret
    }

    private func formatLinkerSettings(flags: [String], separator: String) -> String {
        let firstPrefix = separator
        let nextIndent = "," + separator
        var ret = ""
        for flag in flags {
            let prefix = ret.isEmpty ? firstPrefix : nextIndent
            if let match = flag.firstMatch(of: /^-l(.+)/) {
                let library = String(match.1)
                ret.append("\(prefix).linkedLibrary(\"\(library)\")")
            } else {
                print("Warning: Ignoring linker flag \(flag)")
            }
        }
        return ret
    }
}
