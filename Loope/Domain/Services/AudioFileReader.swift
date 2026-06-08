//
//  AudioFileReader.swift
//  Loope
//
//  Created by Markus Chow on 08.06.26.
//

import Foundation
import AVFoundation

protocol AudioFileReader {
    func read(for url: URL) throws -> AVAudioPCMBuffer
}

final class DefaultAudioFileReader: AudioFileReader {
    func read(for url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameLength = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameLength
        ) else {
            throw AudioEngineError.invalidFileBuffer
        }

        buffer.frameLength = frameLength
        try file.read(into: buffer)
        
        return buffer
    }
}
