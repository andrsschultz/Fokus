//
//  FokusApp.swift
//  Fokus
//
//  Created by Andreas Schultz on 20.12.23.
//

import SwiftUI

@main
 struct FokusApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    @ObservedObject var timerAlt = PomodoroTimer()
    
    
    var body: some Scene {
        WindowGroup {
            TimerView(timer: timerAlt)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                timerAlt.timerEntersForeground()
            } else if newPhase == .background {
                timerAlt.timerEntersBackground()
            }
        }
        
    }
}
