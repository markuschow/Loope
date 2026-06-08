//
//  Loop.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation

struct Loop: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let duration: TimeInterval
    var tempo: Double
    
    init(name: String, url: URL, duration: TimeInterval, tempo: Double = 120.0) {
        self.name = name
        self.url = url
        self.duration = duration
        self.tempo = tempo
    }
}
