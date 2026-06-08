//
//  AudioFileReaderTests.swift
//  LoopeTests
//
//  Created by Markus Chow on 08.06.26.
//

import XCTest
@testable import Loope
import AVFoundation

final class AudioFileReaderTests:XCTest {

    private var testAudioURL: URL!
    
    override func setUp() {
        super.setUp()
        
        guard let url = Bundle(for: type(of: self)).url(forResource: "metronome-120bpm", withExtension: "wav") else {
            XCTFail("Test audio file not found")
            return
        }
        
        testAudioURL = url
    }

    func testRead_SuccessfullyRetursBuffer() throws {
        let reader = DefaultAudioFileReader()
        
        let buffer = try reader.read(for: testAudioURL)
        
        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer.frameLength, buffer.frameCapacity)
        XCTAssertTrue(buffer.frameLength > 0)
    }
    
    func testRead_ThrowsError_ForInvalidFile() throws {
        let reader = DefaultAudioFileReader()
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.wav")
        
        do {
            _ = try reader.read(for: invalidURL)
            XCTFail("Should have thrown an error")
        } catch AudioEngineError.invalidFileBuffer {
            // Expected catch error here
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
