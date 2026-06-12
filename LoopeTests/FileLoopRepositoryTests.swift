//
//  FileLoopRepositoryTests.swift
//  LoopeTests
//
//  Created by Markus Chow on 12.06.26.
//

import XCTest
@testable import Loope

@MainActor
final class FileLoopRepositoryTests:XCTest {

    func testLoadAllAsync() async {
        
        // Create temp directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Add a fake loop
        let fakeLoop = tempDir.appendingPathComponent("test.wav")
        try! Data().write(to: fakeLoop) // dummy file
        
        let repoWithTemp = FileLoopRepository(loopDirectory: tempDir, bundleLoopName: nil)
        
        let loops = try! await repoWithTemp.loadAll()
        XCTAssertEqual(loops.count, 1)
        XCTAssertEqual(loops[0].name, "test")
        
        // Cleanup
        try! FileManager.default.removeItem(at: tempDir)
    }

}
