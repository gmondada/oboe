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
    let tags = git.getTags()
    for (name, _) in tags {
        if !name.hasPrefix("spm-") {
            git.removeTag(name: name)
        }
    }

    for (name, hash) in originalTags {
        print("Adding tag 'original-\(name)'")
        git.addTag(name: "original-" + name, hash: hash)
    }

    for (name, hash) in tags {
        if name.hasPrefix("spm-") {
            let version = String(name.dropFirst(4))
            print("Adding tag '\(version)'")
            git.addTag(name: version, hash: hash)
        }
    }
} else {
    print("Usage:")
    print("  dev cmake2spm        build the Swift Package from the CMake project")
    print("  dev tags             refresh all version tags")
}
