//
//  PlayLoopUseCase.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation

struct PlayLoopInput {
    let loop: Loop
    let tempo: Double
}

protocol PlayLoopUseCase {
    func play(input: PlayLoopInput) -> Result<Void, Error>
    func stop()
    func setRate(_ rate: Float)
    func loadAll() -> [Loop]
}

final class PlayLoopUseCaseImpl: PlayLoopUseCase {
    private let audioPlayer: AudioPlayer
    private let tempoProcessor: TempoProcessing
    private let loopRepository: LoopRepository
    
    init(audioPlayer: AudioPlayer = AudioEngineService(),
         tempoProcessor: TempoProcessing = TempoProcessor(),
         loopRepository: LoopRepository = FileLoopRepository()) {
        
        self.audioPlayer = audioPlayer
        self.tempoProcessor = tempoProcessor
        self.loopRepository = loopRepository
    }
    
    func loadAll() -> [Loop] {
        return loopRepository.loadAll()
    }
    
    func play(input: PlayLoopInput) -> Result<Void, Error> {
        let rate = tempoProcessor.adjustRate(for: input.tempo, baseTempo: 120)
        return audioPlayer.play(loop: input.loop, rate: rate)
    }

    func setRate(_ rate: Float) {
        audioPlayer.setRate(rate)
    }
    
    func stop() {
        audioPlayer.stop()
    }
}
