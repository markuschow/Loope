//
//  LoopPlayerViewModel.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation
import Combine
import AppKit
internal import UniformTypeIdentifiers

@MainActor
final class LoopPlayerViewModel: ObservableObject {
    @Published var loops: [Loop] = []
    @Published var selectedLoopID: Loop.ID? {
        didSet {
            if isPlaying {
                stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
                    guard let self = self else { return }                    
                    playSelectedLoop()
                })
            }
        }
    }
    @Published var isPlaying: Bool = false
    @Published var errorMessage: String?
        
    private let playLoopUseCase: PlayLoopUseCase
    
    @Published var tempo: Double = 120.0 {
        didSet {
            updateRate()
        }
    }
    
    init(playLoopUseCase: PlayLoopUseCase) {
        
        self.playLoopUseCase = playLoopUseCase
        
        Task { await self.loadLoops() }
        
    }
    
    // MARK: - File Import
    
    func importAudioFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select an audio file to add as a loop"
        
        panel.allowedContentTypes = [
            .init(filenameExtension: "wav")!,
            .init(filenameExtension: "mp3")!,
            .init(filenameExtension: "aiff")!
        ]
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = panel.url {
                self.copyAudioFileToLoops(url: url)
            }
        }
    }
    
    private func copyAudioFileToLoops(url: URL) {

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let loopDirectory = documentsURL.appendingPathComponent("Loops")
        
        do {
            try FileManager.default.createDirectory(
                at: loopDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            errorMessage = "Could not create Loops folder"
            return
        }
        
        let originalName = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        
        let ext = url.pathExtension.isEmpty ? "wav" : url.pathExtension
        
        let uuid = UUID().uuidString.prefix(8).lowercased()
        
        let safeName = originalName.isEmpty ? "audio_\(uuid)" : "\(originalName)_\(uuid)"
        
        let destURL = loopDirectory.appendingPathComponent("\(safeName).\(ext.lowercased())")
                
        do {
            guard FileManager.default.fileExists(atPath: url.path),
                  try url.checkResourceIsReachable() else {
                errorMessage = "Source file not found"
                return
            }
            
            try FileManager.default.copyItem(at: url, to: destURL)
            
            guard FileManager.default.fileExists(atPath: destURL.path) else {
                errorMessage = "File copy failed"
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Force reload to pick up new file
                Task { await self.loadLoops() }
                                
                // Auto-select the newly added loop
                if let newLoop = self.loops.first(where: { $0.url == destURL }) {
                    // Found new loop
                    self.selectedLoopID = newLoop.id
                } else {
                    print("New loop not found in list")
                    for loop in self.loops {
                        print("Loop URL: \(loop.url.path)")
                    }
                }
            }
            
        } catch {
            errorMessage = "Failed to import file: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Loop Management
    
    func loadLoops() async {
        
        do {
            loops = try await playLoopUseCase.loadAll()
            
            // Auto-select first loop if none selected
            if selectedLoopID == nil, let firstLoop = loops.first {
                selectedLoopID = firstLoop.id
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load loops: \(error)")
        }
                        
    }

    
    func loadDemoLoop() {
        if let demoLoop = loops.first(where: { $0.name.contains("metronome") }) {
            selectedLoopID = demoLoop.id
            playSelectedLoop()
        }
    }
    
    // MARK: - Playback
    
    func updateRate() {
        guard isPlaying else { return }
        
        let rate = Float(tempo / 120.0)
        
        playLoopUseCase.setRate(rate)
    }
    
    func playSelectedLoop() {
        guard !isPlaying else {
            stop()
            return
        }
        
        guard let loop = loops.first(where: { $0.id == selectedLoopID }) else {
            errorMessage = "No loop selected"
            return
        }
        
        let input = PlayLoopInput(loop: loop, tempo: tempo)
        switch playLoopUseCase.play(input: input) {
        case .success:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isPlaying = true
                self.errorMessage = nil
            }
        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isPlaying = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func stop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            isPlaying = false
            playLoopUseCase.stop()
        }
    }
}

