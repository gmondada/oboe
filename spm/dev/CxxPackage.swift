import Foundation

struct CxxPackage {
    let sources: [URL]
    let privateIncludes: [URL]
    let publicIncludes: [URL]
    let cFlags: [String]
    let cppFlags: [String]
    let linkFlags: [String]
}
