//
//  LoopeApp.swift
//  Loope
//
//  Created by Markus Chow on 08.06.26.
//

import SwiftUI

@main
struct LoopeApp: App {
    let loopPlayUseCase: PlayLoopUseCase
    let loopPlayViewModel: LoopPlayerViewModel
    
    init() {
        self.loopPlayUseCase = PlayLoopUseCaseImpl()
        self.loopPlayViewModel = LoopPlayerViewModel(playLoopUseCase: loopPlayUseCase)
    }
    
    var body: some Scene {
        WindowGroup {
            LoopPlayerView(viewModel: loopPlayViewModel)
        }
    }
}
