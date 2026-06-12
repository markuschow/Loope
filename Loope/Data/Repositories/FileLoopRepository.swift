//
//  FileLoopRepository.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation
import Combine
import AVFoundation

enum LoopRepositoryError: LocalizedError, CustomDebugStringConvertible {
    case directoryCreationFailed(URL, underlying: Error)
    case readFailed(URL, underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let url, let underlying):
            return "Failed to create loop directory at \(url.path): \(underlying.localizedDescription)"
        case .readFailed(let url, let underlying):
            return "Failed to read loops from \(url.path): \(underlying.localizedDescription)"
        }
    }
    
    var debugDescription: String {
        errorDescription ?? "LoopRepositoryError"
    }
}

protocol LoopRepository {
    
    func loadAll() async throws -> [Loop]
    
    func loopsPublisher() -> AnyPublisher<[Loop], Error>
}

@MainActor
final class FileLoopRepository: LoopRepository, @unchecked Sendable {
    
    private let loopDirectory: URL
    private let bundleLoopName: String?
    
    private let subject = PassthroughSubject<[Loop], Error>()
    
    private var cachedLoops: [Loop] = []
    
    init(
        loopDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Loops"),
        bundleLoopName: String? = "metronome-120bpm"
    ) {
        self.loopDirectory = loopDirectory
        self.bundleLoopName = bundleLoopName
        
        guard loopDirectory.isFileURL else {
            fatalError("Loop directory must be a file URL: \(loopDirectory)")
        }
        
        do {
            try FileManager.default.createDirectory(
                at: loopDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            print("Could not create loop directory: \(error)")
        }
    }
    
    func loadAll() async throws -> [Loop] {
        try Task.checkCancellation()

        let contents = try await Task.detached(priority: .background) { [loopDirectory] in
            do {
                return try FileManager.default.contentsOfDirectory(
                    at: loopDirectory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                )
            } catch {
                throw LoopRepositoryError.readFailed(loopDirectory, underlying: error)
            }
        }.value

        let fileLoops = try await withThrowingTaskGroup(of: Loop?.self) { group in
            for url in contents {

                guard ["wav", "mp3", "aiff"].contains(url.pathExtension.lowercased()) else {
                    continue
                }

                group.addTask { [url] in
                    try Task.checkCancellation()
                    
                    let duration = try await self.loadDuration(for: url)

                    guard duration.isFinite, duration > 0 else {
                        return nil
                    }

                    return await Loop(
                        name: url.deletingPathExtension().lastPathComponent,
                        url: url,
                        duration: duration
                    )
                }
            }

            var loops = [Loop]()

            do {
                for try await loop in group {

                    if let loop {
                        loops.append(loop)
                    }
                }
            } catch {
                group.cancelAll()
                throw error
            }

            return loops
        }

        var loops = fileLoops

        if let bundleLoopName = bundleLoopName,
           let url = Bundle.main.url(forResource: bundleLoopName, withExtension: "wav") {

            if !loops.contains(where: { $0.url == url }) {
                let duration = try await loadDuration(for: url)

                loops.append(
                    Loop(
                        name: bundleLoopName,
                        url: url,
                        duration: (duration.isFinite && duration > 0) ? duration : 2.0
                    )
                )
            }
        }
        
        try Task.checkCancellation()

        let sortedLoops = loops.sorted { $0.name < $1.name }

        cachedLoops = sortedLoops
        subject.send(sortedLoops)

        return sortedLoops
    }
    
    private func loadDuration(for url: URL) async throws -> Double {
        try Task.checkCancellation()
        
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            let syncDuration = CMTimeGetSeconds(asset.duration)
            return (syncDuration.isFinite && syncDuration > 0) ? syncDuration : 2.0
        }
    }
    
    func loopsPublisher() -> AnyPublisher<[Loop], Error> {
        subject.eraseToAnyPublisher()
    }
    
    func refresh() async {
        do {
            _ = try await loadAll()
        } catch {
            subject.send(completion: .failure(error))
        }
    }
}
