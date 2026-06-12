//
//  MockAudioFileReader.swift
//  Loope
//
//  Created by Markus Chow on 12.06.26.
//

import XCTest
@testable import Loope
import AVFoundation

final class MockAudioFileReader: AudioFileReader {
    var bufferToReturn: AVAudioPCMBuffer?
    var errorToThrow: Error?
    
    func read(for url: URL) throws -> AVAudioPCMBuffer {
        if let error = errorToThrow {
            throw error
        }
        
        guard let buffer = bufferToReturn else {
            throw AudioEngineError.invalidFileBuffer
        }
        
        return buffer
    }
}
