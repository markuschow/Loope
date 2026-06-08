//
//  TempoProcessor.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation

protocol TempoProcessing {
    func adjustRate(for tempo: Double, baseTempo: Double) -> Float
}

final class TempoProcessor: TempoProcessing {
    let baseTempo: Double
    
    init(baseTempo: Double = 120) {
        self.baseTempo = baseTempo
    }
    
    func adjustRate(for tempo: Double, baseTempo: Double = 120) -> Float {
        guard tempo > 0, baseTempo > 0 else { return 1.0 }
        
        let ratio = tempo / baseTempo
        
        // Clamp to safe ranage (0.5 - 2.0x) to avoid artifacts
        let clamped = max(0.5, min(2.0, ratio))
        
        return Float(clamped)
    }
    
}
