import Foundation

struct git {
    static func getRemoteTags(repoUrl: String) -> [String: String] {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["git", "ls-remote", "--tags", repoUrl]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8)!
        // parse tag list
        let lines = text.split(separator: "\n")
        var tags: [String: String] = [:]
        for line in lines {
            let components = line.split(separator: "\t")
            if components.count == 2 {
                let hash = String(components[0])
                let ref = String(components[1]).replacingOccurrences(of: "refs/tags/", with: "")
                if ref.hasSuffix("^{}") {
                    // give preference to this tag, which points to the commit
                    let ref = String(ref.dropLast(3))
                    tags.removeValue(forKey: ref)
                    tags[ref] = hash
                } else {
                    // use this tag only if there is not ^{} tag
                    if !tags.keys.contains(ref) {
                        tags[ref] = hash
                    }
                }
            }
        }
        return tags
    }

    static func removeLocalTags() {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["git", "tag", "-l"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8)!
        let tags = text.split(separator: "\n").map { String($0) }
        for tag in tags {
            let deleteTask = Process()
            deleteTask.launchPath = "/usr/bin/env"
            deleteTask.arguments = ["git", "tag", "-d", tag]
            deleteTask.launch()
            deleteTask.waitUntilExit()
        }
    }

    static func addTag(name: String, hash: String) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["git", "tag", name, hash]
        task.launch()
        task.waitUntilExit()
    }

    static func getCommits() -> [String: String] {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["git", "log", "--all", "--pretty=format:%H\t%s"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8)!
        let lines = text.split(separator: "\n")
        var commits: [String: String] = [:]
        for line in lines {
            let components = line.split(separator: "\t")
            if components.count == 2 {
                let hash = String(components[0])
                let message = String(components[1])
                commits[hash] = message
            }
        }
        return commits
    }
}
