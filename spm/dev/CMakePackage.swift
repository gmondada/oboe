import Foundation

class CMakePackage {
    private let buildUrl: URL
    private let indexFile: URL
    private let index: Index

    let codemodel: Codemodel
    let toolchains: Toolchains
    let target: Target
    let directory: Directory

    init(buildUrl: URL) {
        self.buildUrl = buildUrl
        let replyDir = buildUrl.appendingPathComponent(".cmake")
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("reply", isDirectory: true)
        let fileManager = FileManager.default
        var indexFile: URL?
        if let files = try? fileManager.contentsOfDirectory(at: replyDir, includingPropertiesForKeys: nil) {
            for file in files {
                if file.lastPathComponent.hasPrefix("index-") {
                    indexFile = file
                    break
                }
            }
        }
        guard let indexFile else {
            fatalError("No index file found in \(replyDir.path)")
        }
        self.indexFile = indexFile
        do {
            self.index = try JSONDecoder().decode(Index.self, from: Data(contentsOf: indexFile))
        } catch let error {
            fatalError("Failed to read index file \(indexFile.path): \(error)")
        }

        let codemodelFile = replyDir.appendingPathComponent(index.reply.codemodel.jsonFile)
        do {
            self.codemodel = try JSONDecoder().decode(Codemodel.self, from: Data(contentsOf: codemodelFile))
        } catch let error {
            fatalError("Failed to read codemodel file \(codemodelFile.path): \(error)")
        }

        let toolchainsFile = replyDir.appendingPathComponent(index.reply.toolchains.jsonFile)
        do {
            self.toolchains = try JSONDecoder().decode(Toolchains.self, from: Data(contentsOf: toolchainsFile))
        } catch let error {
            fatalError("Failed to read toolchains file \(toolchainsFile.path): \(error)")
        }

        guard self.codemodel.configurations.count == 1 else {
            fatalError("Multiple configurations not supported")
        }

        guard self.codemodel.configurations.first!.targets.count == 1 else {
            fatalError("Multiple targets not supported")
        }

        let targetFile = replyDir.appendingPathComponent(self.codemodel.configurations.first!.targets.first!.jsonFile)
        do {
            self.target = try JSONDecoder().decode(Target.self, from: Data(contentsOf: targetFile))
        } catch let error {
            fatalError("Failed to read target file \(targetFile.path): \(error)")
        }

        guard self.target.sourceGroups.count == 1 else {
            fatalError("Multiple source groups not supported")
        }

        let sourcesIndexes = Set<Int>(self.target.sourceGroups.first!.sourceIndexes)
        guard sourcesIndexes.count == self.target.sourceGroups.first!.sourceIndexes.count else {
            fatalError("Partial source list selection not supported (1)")
        }

        let sourceIndexMax = sourcesIndexes.max() ?? -1
        guard sourceIndexMax != self.target.sources.count else {
            fatalError("Partial source list selection not supported (2)")
        }

        guard self.codemodel.configurations.first!.directories.count == 1 else {
            fatalError("Multiple directories not supported")
        }

        let directoryFile = replyDir.appendingPathComponent(self.codemodel.configurations.first!.directories.first!.jsonFile)
        do {
            self.directory = try JSONDecoder().decode(Directory.self, from: Data(contentsOf: directoryFile))
        } catch let error {
            fatalError("Failed to read directory file \(directoryFile.path): \(error)")
        }
    }

    lazy var projectDir = URL(fileURLWithPath: codemodel.paths.source)

    var sourceFiles: [URL] {
        return target.sources.map { projectDir.appendingPathComponent($0.path) }
    }

    var includeDirs: [URL] {
        guard target.compileGroups.count == 1 else {
            fatalError("Multiple compile groups not supported")
        }
        return self.target.compileGroups.first!.includes.map { URL(fileURLWithPath: $0.path) }
    }

    lazy var includeFiles: [URL] = headerFilesInDirs(includeDirs)

    var publicIncludeDirs: [URL] {
        var ret = [URL]()
        for installer in directory.installers {
            if installer.type == "directory" {
                for path in installer.paths {
                    let url = URL(fileURLWithPath: path, isDirectory: true, relativeTo: projectDir)
                    for includeUrl in includeDirs {
                        if url.absoluteString.hasPrefix(includeUrl.absoluteString) {
                            ret.append(includeUrl)
                            break
                        }
                    }
                }
            }
        }
        return ret
    }

    lazy var publicIncludeFiles: [URL] = headerFilesInDirs(publicIncludeDirs)

    var privateIncludeDirs: [URL] {
        let dirs = includeDirs
        let publicDirs = publicIncludeDirs
        return dirs.filter { !publicDirs.contains($0) }
    }

    lazy var privateIncludeFiles: [URL] = headerFilesInDirs(privateIncludeDirs)

    var cxxFlags: [String] {
        guard target.compileGroups.count == 1 else {
            fatalError("Multiple compile groups not supported")
        }
        var flags = [String]()
        for fragment: TargetCompileFragment in target.compileGroups.first!.compileCommandFragments {
            let fArray = fragment.fragment.split(separator: Character(" ")).filter { $0 != "" }
            flags.append(contentsOf: fArray.map { String($0) })
        }
        return flags
    }

    var linkFlags: [String] {
        var flags = [String]()
        for fragment: TargetLinkFragment in target.link.commandFragments {
            let fArray = fragment.fragment.split(separator: Character(" ")).filter { $0 != "" }
            flags.append(contentsOf: fArray.map { String($0) })
        }
        return flags
    }

    var cxxPackage: CxxPackage {
        let sourceFiles = self.sourceFiles
        let sourceBase = baseUrl(of: sourceFiles)!
        let privateIncludes = privateIncludeFiles
        let publicIncludes = publicIncludeFiles
        return CxxPackage(sources: rebaseUrls(sourceFiles, relativeTo: sourceBase), privateIncludes: privateIncludes, publicIncludes: publicIncludes, cFlags: [], cppFlags: cxxFlags, linkFlags: linkFlags)
    }

    private func rebaseUrl(_ url: URL, relativeTo baseUrl: URL) -> URL {
        let base = baseUrl.standardized
        precondition(url.scheme == base.scheme)
        precondition(base.hasDirectoryPath)
        let baseComponents = base.pathComponents
        let components = url.pathComponents
        for (index, baseComponent) in baseComponents.enumerated() {
            if index >= components.count && baseComponent != components[index] {
                fatalError("cannot rebase url \(url.absoluteString) onto \(base.absoluteString)")
            }
        }
        var relativeUrl = URL(string: ".", relativeTo: base)!
        let relativeComponents = components[baseComponents.count...]
        for component in relativeComponents {
            relativeUrl.appendPathComponent(component)
        }
        return relativeUrl.standardized
    }

    private func rebaseUrls(_ urls: [URL], relativeTo baseUrl: URL) -> [URL] {
        return urls.map { self.rebaseUrl($0, relativeTo: baseUrl) }
    }

    private func headerFilesInDir(_ dir: URL) -> [URL] {
        precondition(dir.hasDirectoryPath)
        var ret: [URL] = []
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey]) {
            for file in files {
                if file.hasDirectoryPath {
                    let subFiles = headerFilesInDir(file)
                    ret.append(contentsOf: subFiles)
                } else if (file.pathExtension == "h" || file.pathExtension == "hpp") {
                    ret.append(file)
                }
            }
        }
        return rebaseUrls(ret, relativeTo: dir)
    }

    private func headerFilesInDirs(_ dirs: [URL]) -> [URL] {
        var ret: [URL] = []
        for dir in dirs {
            let subFiles = headerFilesInDir(dir)
            ret.append(contentsOf: subFiles)
        }
        return ret
    }

    private func baseUrl(of urls: [URL]) -> URL? {
        guard urls.count > 0 else {
            return nil
        }
        var baseUrl = urls.first!.standardized
        var baseComponents = baseUrl.pathComponents
        guard baseComponents.count > 0 else {
            return nil
        }
        for url in urls {
            if url.scheme != baseUrl.scheme {
                return nil
            }
            let standardUrl = url.standardized
            while Array(standardUrl.pathComponents[0..<baseComponents.count]) != baseComponents {
                baseUrl.deleteLastPathComponent()
                baseComponents.removeLast()
                if baseComponents.count == 0 {
                    return nil
                }
            }
        }
        return baseUrl
    }
}
