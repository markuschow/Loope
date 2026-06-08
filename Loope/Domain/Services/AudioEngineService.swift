//
//  AudioEngineService.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation
import AVFoundation

enum AudioEngineError: Error {
    case fileNotFound
    case invalidFileBuffer
}

protocol AudioPlayer {
    func play(loop: Loop, rate: Float) -> Result<Void, Error>
    func stop()
    func setRate(_ rate: Float)
}

final class AudioEngineService: AudioPlayer {
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private let fileReader: AudioFileReader
    
    internal lazy var playerNode: AVAudioPlayerNode = {
        let node = AVAudioPlayerNode()
        self.engine.attach(node)
        return node
    }()
    
    internal lazy var timePitchUnit: AVAudioUnitTimePitch = {
        let unit = AVAudioUnitTimePitch()
        self.engine.attach(unit)
        return unit
    }()
    
    init(fileReader: AudioFileReader = DefaultAudioFileReader()) {
        self.fileReader = fileReader
        setupEngine()
    }
    
    deinit {
        stop()
        engine.stop()
    }
    
    private func setupEngine() {
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        timePitchUnit = AVAudioUnitTimePitch()
        engine.attach(timePitchUnit)
        
        // Chain: Player to Time Pitch to Main Mixer
        engine.connect(playerNode, to: timePitchUnit, format: nil)
        engine.connect(timePitchUnit, to: engine.mainMixerNode, format: nil)
    }
    
    private func safeRate(_ rate: Float) -> Float {
        max(0.5, min(2.0, rate))
    }
    
    func setRate(_ rate: Float) {
        timePitchUnit.rate = safeRate(rate)
    }
    
    func play(loop: Loop, rate: Float) -> Result<Void, any Error> {
        do {
            let rawBuffer = try fileReader.read(for: loop.url)
            
            let engineFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            
            let shouldConvertFormat = !rawBuffer.format.isEqual(to: engineFormat)

            let finalBuffer: AVAudioPCMBuffer
            if shouldConvertFormat {
                finalBuffer = try convertBuffer(rawBuffer, to: engineFormat)
            } else {
                finalBuffer = rawBuffer
            }
            
            playerNode.scheduleBuffer(finalBuffer, at: nil, options: .loops)

            setRate(rate)
            
            try engine.start()
            playerNode.play()
            
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: Convert buffer format (mono to stereo, etc.)
    internal func convertBuffer(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let sourceFormat = buffer.format
        guard !sourceFormat.isEqual(to: targetFormat) else {
            return buffer
        }
        
        let converter = AVAudioConverter(from: sourceFormat, to: targetFormat)!
        
        // Calculate output frame count (may differ due to sample rate)
        let sourceSampleRate = sourceFormat.sampleRate
        let targetSampleRate = targetFormat.sampleRate
        let frameCount = AVAudioFrameCount(
            Double(buffer.frameLength) * (targetSampleRate / sourceSampleRate)
        )
        
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: frameCount
        ) else {
            throw AudioEngineError.fileNotFound
        }
        
        convertedBuffer.frameLength = frameCount
        
        var error: NSError?
        let status = converter.convert(
            to: convertedBuffer,
            error: &error
        ) { inNumFrames, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard status == .haveData else {
            throw error ?? AudioEngineError.fileNotFound
        }
        
        return convertedBuffer
    }

    func stop() {
        playerNode.stop()
    }
}
