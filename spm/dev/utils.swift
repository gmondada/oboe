import Foundation

func androidNdk() -> URL? {
    if let path = ProcessInfo.processInfo.environment["ANDROID_NDK"] {
        return URL(fileURLWithPath: path)
    }
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let ndkDir = homeDir
        .appendingPathComponent("Library")
        .appendingPathComponent("Android")
        .appendingPathComponent("sdk")
        .appendingPathComponent("ndk")
    if FileManager.default.fileExists(atPath: ndkDir.path) {
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: ndkDir.path) {
            let sortedVersions = versions.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })
            if let latestVersion = sortedVersions.first {
                return ndkDir.appendingPathComponent(latestVersion)
            }
        }
    }
    return nil
}

func cmake(args: [String]) {
    guard let cmakePath = searchCommand("cmake") else {
        fatalError("CMake not found")        
    }
    let process = Process()
    process.executableURL = cmakePath
    process.arguments = args

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        fatalError("Failed to run CMake: \(error)")
    }
}

func createCMakeQueries(buildUrl: URL) {
    let queryDir = buildUrl.appendingPathComponent(".cmake")
        .appendingPathComponent("api")
        .appendingPathComponent("v1")
        .appendingPathComponent("query", isDirectory: true)

    try! FileManager.default.createDirectory(at: queryDir, withIntermediateDirectories: true)
    let codemodelFile = queryDir.appendingPathComponent("codemodel-v2")
    FileManager.default.createFile(atPath: codemodelFile.path, contents: nil)
    let toolchainsFile = queryDir.appendingPathComponent("toolchains-v1")
    FileManager.default.createFile(atPath: toolchainsFile.path, contents: nil)
}

func searchCommand(_ command: String) -> URL? {
    return searchInEnvPath(command: command)
        ?? searchInShell(shell: "zsh", command: command)
        ?? searchInShell(shell: "bash", command: command)
}

func searchInEnvPath(command: String) -> URL? {
    let fileManager = FileManager.default
    let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
    let paths = pathEnv.split(separator: ":").map { String($0) }

    for path in paths {
        let cmdUrl = URL(fileURLWithPath: path).appendingPathComponent(command)
        if fileManager.fileExists(atPath: cmdUrl.path) {
            return cmdUrl
        }
    }

    return nil
}

func searchInShell(shell: String, command: String) -> URL? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/\(shell)")
    process.arguments = ["-c", "which \(command)"]

    let pipe = Pipe()
    process.standardOutput = pipe

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return URL(fileURLWithPath: output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    } catch {
        return nil
    }

    return nil
}

func removeDirectoryContent(at url: URL) {
    let fileManager = FileManager.default
    let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    for item in contents ?? [] {
        if item.lastPathComponent != "." && item.lastPathComponent != ".." {
            // ignore this item
        } else if item.hasDirectoryPath {
            removeDirectoryContent(at: item)
        } else {
            try? fileManager.removeItem(at: item)
        }
    }
}
