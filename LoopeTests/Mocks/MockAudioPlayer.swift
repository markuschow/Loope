//
//  MockAudioPlayer.swift
//  Loope
//
//  Created by Markus Chow on 12.06.26.
//

import XCTest
@testable import Loope
import AVFoundation

final class MockAudioPlayer: AudioPlayer {
    var lastLoop: Loop?
    var lastRate: Float?
    var shouldSucceed: Bool = true
    var isPlaying: Bool = false
    
    func play(loop: Loope.Loop, rate: Float) -> Result<Void, any Error> {
        lastLoop = loop
        lastRate = rate
        isPlaying = true
        
        return shouldSucceed ? .success(()) : .failure(AudioEngineError.fileNotFound)
    }

    func setRate(_ rate: Float) {
        lastRate = rate
    }
    
    func stop() {
        isPlaying = false
    }
}
