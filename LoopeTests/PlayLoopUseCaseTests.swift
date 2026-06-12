//
//  PlayLoopUseCaseTests.swift
//  LoopeUITests
//
//  Created by Markus Chow on 05.06.26.
//

import XCTest
@testable import Loope

@MainActor
final class PlayLoopUseCaseTests: XCTestCase {
    var useCase: PlayLoopUseCase!
    var mockPlayer: MockAudioPlayer!
    
    override func setUp() {
        super.setUp()
        mockPlayer = MockAudioPlayer()
        useCase = PlayLoopUseCaseImpl(audioPlayer: mockPlayer,
                                      tempoProcessor: TempoProcessor(),
                                      loopRepository: FileLoopRepository())
        
    }
    
    override func tearDown() {
        mockPlayer = nil
        useCase = nil
        super.tearDown()
    }
    
    func testPlay_Success() {
        let loop = Loop(name: "test", url: URL(fileURLWithPath: "/temp/test.wav"), duration: 2.0)
        let input = PlayLoopInput(loop: loop, tempo: 180)
        
        let result = useCase.play(input: input)
        
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(mockPlayer.lastLoop?.name, "test")
        XCTAssertEqual(mockPlayer.lastRate, 1.5) // 180 / 120
    }
    
    func testPlay_Failure() {
        mockPlayer.shouldSucceed = false
        
        let loop = Loop(name: "test", url: URL(fileURLWithPath: "/temp/test.wav"), duration: 2.0)
        let input = PlayLoopInput(loop: loop, tempo: 180)
        
        let result = useCase.play(input: input)
        
        XCTAssertThrowsError(try result.get())
    }
    
    func testSetRate() {
        useCase.setRate(1.5)
        
        XCTAssertEqual(mockPlayer.lastRate, 1.5)
    }
    
    func testShouldStop() {
        useCase.stop()
        
        XCTAssertFalse(mockPlayer.isPlaying)
    }
}
