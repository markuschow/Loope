//
//  MockTempoProcessing.swift
//  Loope
//
//  Created by Markus Chow on 12.06.26.
//

import XCTest
@testable import Loope

final class MockTempoProcessing: TempoProcessing {
    func adjustRate(for tempo: Double, baseTempo: Double) -> Float { 1.0 }
}
