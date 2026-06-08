//
//  LoopPlayerView.swift
//  Loope
//
//  Created by Markus Chow on 05.06.26.
//

import Foundation
import SwiftUI

struct LoopPlayerView: View {
    @StateObject var viewModel: LoopPlayerViewModel
    @State private var selectedID: Loop.ID?

    private let loopDirURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("Loops")
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Loope")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading) {
                Text("Loop Directory")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(loopDirURL.path)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            
            Button("Import Audio File") {
                viewModel.importAudioFile()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("Load Demo Loop") {
                viewModel.loadDemoLoop()
                selectedID = viewModel.selectedLoopID
            }
            .buttonStyle(BorderedButtonStyle())
            
            List(viewModel.loops, selection: $selectedID) { loop in
                Text(loop.name)
                    .tag(loop.id as Loop.ID?)
            }
            .listStyle(SidebarListStyle())
            .onChange(of: selectedID) { _, newValue in
                viewModel.selectedLoopID = newValue
            }
            .onAppear() {
                selectedID = viewModel.selectedLoopID
            }
            
            HStack {
                Button(action: viewModel.playSelectedLoop) {
                    Image(systemName: viewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }

            }
            
            VStack(alignment: .leading) {
                Text("Tempo: \(Int(viewModel.tempo)) BPM")
                    .font(.headline)
                
                Slider(value: $viewModel.tempo, in: 60...240, step: 1)
                    .padding(.horizontal)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

