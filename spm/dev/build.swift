import Foundation

func buildOboe(projectUrl: URL, abi: String) {
    guard let androidNdk = androidNdk() else {
        fatalError("ANDROID_NDK not set")
    }

    let cmakeToolchainFile = androidNdk
        .appendingPathComponent("build")
        .appendingPathComponent("cmake")
        .appendingPathComponent("android.toolchain.cmake")

    let buildUrl = projectUrl.appendingPathComponent("build")

    let cmakeArgs = [
        "-H.",
        "-DBUILD_SHARED_LIBS=true",
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo",
        "-DANDROID_TOOLCHAIN=clang",
        "-DANDROID_STL=c++_shared",
        "-DCMAKE_TOOLCHAIN_FILE=\(cmakeToolchainFile.path)",
        "-DCMAKE_INSTALL_PREFIX=.",
    ]

    let maximumApiLevel = 21

    let abiBuildDir = buildUrl.appendingPathComponent(abi)
    let stagingDir = projectUrl.appendingPathComponent("staging")
    let archiveDir = stagingDir.appendingPathComponent("lib").appendingPathComponent(abi)
    try! FileManager.default.createDirectory(at: abiBuildDir, withIntermediateDirectories: true)
    try! FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)

    let args = [
        "-B\(abiBuildDir.path)",
        "-DANDROID_ABI=\(abi)",
        "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=\(archiveDir.path)",
        "-DANDROID_PLATFORM=android-\(maximumApiLevel)",
    ] + cmakeArgs + [
        "-G", "Ninja"
    ]

    createCMakeQueries(buildUrl: abiBuildDir)
    cmake(args: args)

    let package = CMakePackage(buildUrl: abiBuildDir)

    print("Project Dir: \(package.projectDir.absoluteString)")

    print("Source Files:")
    for (index, source) in package.sourceFiles.enumerated() {
        print("  \(index): \(source.absoluteString)")
    }

    print("Include Dirs:")
    for (index, include) in package.includeDirs.enumerated() {
        print("  \(index): \(include.absoluteString)")
    }

    print("Public Include Dirs:")
    for (index, include) in package.publicIncludeDirs.enumerated() {
        print("  \(index): \(include.absoluteString)")
    }

    print("CXX Flags:")
    for (index, flag) in package.cxxFlags.enumerated() {
        print("  \(index): \(flag)")
    }

    print("Link Flags:")
    for (index, flag) in package.linkFlags.enumerated() {
        print("  \(index): \(flag)")
    }

    let builder = CxxSwiftPackage(projectName: "oboe", projectUrl: projectUrl, package: package.cxxPackage)
    builder.build()
}
