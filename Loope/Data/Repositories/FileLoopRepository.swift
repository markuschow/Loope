//
//  FileLoopRepository.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation

protocol LoopRepository {
    func loadAll() -> [Loop]
}

final class FileLoopRepository: LoopRepository {
    private let loopDirectory: URL
    private let bundleLoopName: String?
    
    init(loopDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Loops"),
         bundleLoopName: String? = "metronome-120bpm") {
        
        self.loopDirectory = loopDirectory
        self.bundleLoopName = bundleLoopName
        
        try? FileManager.default.createDirectory(at: loopDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    func loadAll() -> [Loop] {
        var loops = [Loop]()

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: loopDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            print("Directory contents: \(contents.map { $0.lastPathComponent })")
            
            let fileLoops = contents.compactMap { url -> Loop? in
                
                guard url.pathExtension == "wav" || url.pathExtension == "mp3" || url.pathExtension == "aiff" else {
                    return nil
                }
                
                let loop = Loop(name: url.deletingPathExtension().lastPathComponent,
                                url: url,
                                duration: 2.0)
                return loop
            }
            
            loops.append(contentsOf: fileLoops)
        } catch {
            print("Error reading directory: \(error)")
        }
        
        // Fallback to load bundled demo loop (if exists in app bundle)
        if let bundleLoopName = bundleLoopName,
           let url = Bundle.main.url(forResource: bundleLoopName, withExtension: "wav") {
            // Avoid duplicates
            if !loops.contains(where: { $0.url == url }) {
                let loop = Loop(name: bundleLoopName,
                                url: url,
                                duration: 2.0)

                loops.append(loop)
            }
        } else {
            print("No bundled loop found (bundleLoopName: \(String(describing: bundleLoopName)))")
        }
        
        return loops.sorted { $0.name < $1.name }
    }

    
}
