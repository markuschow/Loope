//
//  LoopeTests.swift
//  LoopeTests
//
//  Created by Markus Chow on 08.06.26.
//

import XCTest
@testable import Loope

@MainActor
final class LoopeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

    func testDemoLoopIsCorrectlyIdentified() throws {
        guard let bundleURL = Bundle.main.url(forResource: "metronome-120bpm", withExtension: "wav") else {
            XCTFail("Demo loop 'metronome-120bpm.wav' not found in bundle")
            return
        }
        
        let demoLoop = Loop(name: "metronome-120bpm",
                            url: bundleURL,
                            duration: 2.0)
        
        XCTAssertTrue(demoLoop.isDemoLoop, "Bundled metronome loop should be identified as demo")
    }
    
    func testUserImportedLoopIsNotDemo() throws {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let userLoopURL = documentsURL.appendingPathComponent("my_guitar_loop.wav")
        
        try "dummy".write(to: userLoopURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: userLoopURL) }
        
        let userLoop = Loop(name: "my_guitar_loop", url: userLoopURL, duration: 3.5)
        
        XCTAssertFalse(userLoop.isDemoLoop, "User-imported loop should not be marked as demo")
    }
    
    func testDemoLoopCannotBeDeletedInViewModel() {
        let bundleURL = Bundle.main.url(forResource: "metronome-120bpm", withExtension: "wav")!
        let demoLoop = Loop(name: "ametronome-120bpm", url: bundleURL, duration: 2.0)
        
        let mockRepo = MockLoopRepository(loops: [demoLoop])
        let mockPlayer = MockAudioPlayer()
        let mockProcessor = MockTempoProcessing()
        
        let viewModel = LoopPlayerViewModel(
            playLoopUseCase: PlayLoopUseCaseImpl(
                audioPlayer: mockPlayer,
                tempoProcessor: mockProcessor,
                loopRepository: mockRepo
            )
        )

        viewModel.remove(loop: demoLoop)
        
        XCTAssertEqual(viewModel.errorMessage, "Cannot delete the built-in demo loop.")
    }
}
