# Loope

A macOS audio loop demo app built with **Clean Architecture**, **SwiftUI**, and **AVAudioEngine**.


## Clean Architecture
- Business logic (e.g., tempo processing) is framework-free to be fully testable
- Audio engine is isolated in `Data/Audio` — easy to mock or swap
- SwiftUI views only render state — no side effects

## Features (Demo)
- Play a loop with tempo adjustment (pitch-preserving rate change)
- Stop playback
- Load loops from Documents/Loops folder (user can import audio files)
- Clean unit tests for core logic

## Tech Stack
- **SwiftUI** (macOS)
- **AVAudioEngine** for audio playback
- **XCTest** for unit tests (Domain & Data layers)
- **Swift Concurrency** ready (can be extended)

## How to Run
1. Build & run on macOS
2. Upload any audio file or use the preloaded metronome demo 
3. Select a loop and play!
