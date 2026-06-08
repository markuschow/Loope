//
//  TempoProcessorTests.swift
//  LoopeTests
//
//  Created by Markus Chow on 05.06.26.
//

import XCTest
@testable import Loope

final class TempoProcessorTests: XCTestCase {
    var processor: TempoProcessor!
    
    override func setUp() {
        super.setUp()
        processor = TempoProcessor(baseTempo: 120.0)
    }
    
    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    func testAdjustedRate_Basic() {
        // Given
        let tempo = 240.0
        
        // When
        let rate = processor.adjustRate(for: tempo)
        
        // Then
        XCTAssertEqual(rate, 2.0, accuracy: 0.01)
    }
    
    func testAdjustedRate_Zero() {
        let tempo = 0.0
        
        let rate = processor.adjustRate(for: tempo)
        
        XCTAssertEqual(rate, 1.0, accuracy: 0.01)
    }
    
    func testAdjustedRate_ClampHigh() {
        let tempo = 500.0
        
        let rate = processor.adjustRate(for: tempo)
        
        XCTAssertEqual(rate, 2.0) // clamped
    }
    
    func testAdjustedRate_ClampLow() {
        let tempo = 30.0
        
        let rate = processor.adjustRate(for: tempo)
        
        XCTAssertEqual(rate, 0.5) // clamped
    }
    
    func testAdjustedRate_InvalidInput_Returns_1() {
        XCTAssertEqual(processor.adjustRate(for: 0), 1.0)
        XCTAssertEqual(processor.adjustRate(for: -10), 1.0)
    }
}
