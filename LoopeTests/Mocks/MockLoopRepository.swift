//
//  MockLoopRepository.swift
//  Loope
//
//  Created by Markus Chow on 12.06.26.
//

import XCTest
@testable import Loope
import Combine

final class MockLoopRepository: LoopRepository {
    let loops: [Loop]
    init(loops: [Loop]) { self.loops = loops }
    
    func loadAll() async throws -> [Loop] { loops }
    func loopsPublisher() -> AnyPublisher<[Loop], Error> {
        Just(loops).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
