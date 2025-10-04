import Foundation

let projectUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let cmake2spmURL = projectUrl
    .appendingPathComponent("spm")
    .appendingPathComponent("dev")

guard FileManager.default.fileExists(atPath: cmake2spmURL.path) else {
    print("Error: You must run this tool in the package root directory")
    exit(1)
}

if CommandLine.argc >= 2 && CommandLine.arguments[1] == "cmake2spm" {
    buildOboe(projectUrl: projectUrl, abi: "arm64-v8a")
} else if CommandLine.argc >= 2 && CommandLine.arguments[1] == "tags" {
    let originalTags = git.getRemoteTags(repoUrl: "https://github.com/google/oboe.git")
    git.removeLocalTags()
    for (name, hash) in originalTags {
        print("Adding tag 'original-\(name)'")
        git.addTag(name: "original-" + name, hash: hash)
    }
    let commits = git.getCommits()
    for (hash, message) in commits {
        if let match = message.firstMatch(of: /@tag\s+([0-9\.]+)/) {
            let tag = String(match.1)
            print("Extract tag \(tag) from commit \(hash)")
            git.addTag(name: tag, hash: hash)
        }
    }
} else {
    print("Usage:")
    print("  dev cmake2spm        build the Swift Package from the CMake project")
    print("  dev tags             clean all git tags and rebuild them from annotations in the commit messages")
}
