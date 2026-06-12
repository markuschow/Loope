//
//  AudioEngineServiceTests.swift
//  LoopeTests
//
//  Created by Markus Chow on 08.06.26.
//

import XCTest
@testable import Loope
import AVFoundation

final class AudioEngineServiceTests: XCTestCase {

    var service: AudioEngineService!
    var mockReader: MockAudioFileReader!
    
    override func setUp() {
        super.setUp()
        
        mockReader = MockAudioFileReader()
        service = AudioEngineService(fileReader: mockReader)
    }

    override func tearDown() {
        service.stop()
        super.tearDown()
    }
    
    // MARK: - Format compatibility tests
    
    func testPlay_Succeeds_WhenFormatMatch() async throws {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 44100,
                                   channels: 2,
                                   interleaved: false)
        
        let buffer = makeBuffer(with: format)
        
        mockReader.bufferToReturn = buffer
        
        let result = await service.play(loop: makeLoop(), rate: 1.0)
        
        XCTAssertNoThrow(try result.get())
    }
    
    func testPlay_Succeeds_WhenFormatDiffer() async throws {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 44100,
                                   channels: 1, // mono
                                   interleaved: false)
        
        let buffer = makeBuffer(with: format)
        
        mockReader.bufferToReturn = buffer
        
        let result = await service.play(loop: makeLoop(), rate: 1.0)
        
        XCTAssertNoThrow(try result.get())
    }
    
    func testPlay_Fails_WhenFileNotFound() async throws {
        mockReader.errorToThrow = AudioEngineError.fileNotFound
        
        let result = await service.play(loop: makeLoop(), rate: 1.0)
        
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertTrue(error is AudioEngineError)
        }
    }
    
    func testPlay_Fails_WhenConversionFails() async throws {
        let sourceFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 44100,
                                         channels: 2,
                                         interleaved: false)
        let buffer = makeBuffer(with: sourceFormat)
        
        mockReader.bufferToReturn = buffer
        mockReader.errorToThrow = AudioEngineError.invalidFileBuffer
        
        let result = await service.play(loop: makeLoop(), rate: 1.0)
        
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertTrue(error is AudioEngineError)
        }
    }
    
    @MainActor
    func testSetRate_ClampsToValidRange() async throws {
        service.setRate(0.1)
        XCTAssertEqual(service.timePitchUnit.rate, 0.5)
        
        service.setRate(3.0)
        XCTAssertEqual(service.timePitchUnit.rate, 2.0)
        
        service.setRate(1.5)
        XCTAssertEqual(service.timePitchUnit.rate, 1.5)
    }
    
    @MainActor
    func testStop_StopsPlayerNode() async throws {
        let buffer = makeBuffer()
        mockReader.bufferToReturn = buffer
        
        let _ = service.play(loop: makeLoop(), rate: 1.0)
        
        service.stop()
        
        XCTAssertFalse(service.playerNode.isPlaying)
    }
    
    // MARK: - Conversion Logic Tests
    
    func testConvertBuffer_SameFormat_ReturnsSameInsatnsce() throws {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 44100,
                                   channels: 2,
                                   interleaved: false)!
        let buffer = makeBuffer(with: format)
        
        let result = try service.convertBuffer(buffer, to: format)
        
        XCTAssertTrue(result === buffer)
    }
    
    func testConvertBuffer_DifferentFormat_ConvertsSuccessfully () throws {
        let sourceformat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 44100,
                                         channels: 1,
                                         interleaved: false)!
        let targetformat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 48000,
                                         channels: 2,
                                         interleaved: false)!
        let buffer = makeBuffer(with: sourceformat)
        
        let result = try service.convertBuffer(buffer, to: targetformat)
        
        XCTAssertEqual(result.format.sampleRate, 48000)
        XCTAssertEqual(result.format.channelCount, 2)
        XCTAssertGreaterThan(result.frameLength, 0)
    }
    
    // MARK: - Helper Methods
    
    private func makeLoop() -> Loop {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        return Loop(name: "test", url: url, duration: 2.0)
    }
    
    private func makeBuffer(with format: AVAudioFormat? = nil) -> AVAudioPCMBuffer {
        let fmt = format ?? AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: 44100,
                                          channels: 2,
                                          interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 4410)!
        buffer.frameLength = 4410
        return buffer
    }
}

