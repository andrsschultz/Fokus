//
//  FokusWidgetLiveActivity.swift
//  FokusWidget
//
//  Created by Andreas Schultz on 20.12.23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FokusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var secondsRemaining: Int
        var timerState: String
        var numberOfPomodoros: Int
        var currentPomodoro: Int
        
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FokusWidgetLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FokusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                if context.state.timerState == "stopped" || context.state.timerState == "off" {
                    HStack {
                        Text("Ready to Start Focus Session")
                            .monospaced()
                    }
                } else if context.state.timerState == "running" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                        Text("Focusing")
                            .monospaced()
    //                        Text("\(secondsToTimeStamp(seconds: context.state.secondsRemaining))")
    //                            .monospaced()
                        Text(timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.secondsRemaining), since: .now))
                            .monospaced()
                            .frame(width: 100)
                    }
                } else if context.state.timerState == "focusPaused" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                        Text("Focus Paused")
                            .monospaced()
                        Text("\(secondsToTimeStamp(seconds: context.state.secondsRemaining))")
                            .monospaced()
                            .frame(width: 100)
                    }
                } else if context.state.timerState == "bigBreak" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                        Text("Long Break")
                            .monospaced()
                        Text(timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.secondsRemaining), since: .now))
                            .monospaced()
                            .frame(width: 100)
                    }
                } else if context.state.timerState == "smallBreak" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                        Text("Small Break")
                            .monospaced()
                        Text(timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.secondsRemaining), since: .now))
                            .monospaced()
                            .frame(width: 100)
                    }
                } else if context.state.timerState == "readyToStartPause" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                            .frame(width: 120)
                        Text("Ready to Start Pause")
                            .monospaced()
                    }
                } else if context.state.timerState == "readyToStartFocusTimer" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                            .frame(width: 120)
                        Text("Ready to Start Focus")
                            .monospaced()
                    }
                } else if context.state.timerState == "bigBreakPaused" || context.state.timerState ==  "smallBreakPaused" {
                    HStack {
                        PomodoroIndicatorForLiveActivity(timerState: TimerState(rawValue: context.state.timerState) ?? TimerState.off, numberOfPomodoros: context.state.numberOfPomodoros, currentPomodoro: context.state.currentPomodoro)
                        Text("Break Paused")
                            .monospaced()
                        Text("\(secondsToTimeStamp(seconds: context.state.secondsRemaining))")
                            .monospaced()
                            .frame(width: 100)
                    }
                }
            }
            .activityBackgroundTint(Color("startButtonColor"))
            .activitySystemActionForegroundColor(Color("textColor"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    
                }
                DynamicIslandExpandedRegion(.trailing) {
                    
                }
                DynamicIslandExpandedRegion(.bottom) {
                    
                }
            } compactLeading: {
                
            } compactTrailing: {
                
            } minimal: {
                
            }
        }
    }
}

extension FokusWidgetAttributes {
    fileprivate static var preview: FokusWidgetAttributes {
        FokusWidgetAttributes(name: "World")
    }
}

extension FokusWidgetAttributes.ContentState {
     fileprivate static var starEyes: FokusWidgetAttributes.ContentState {
         FokusWidgetAttributes.ContentState(secondsRemaining: 60, timerState: "running", numberOfPomodoros: 6, currentPomodoro: 3)
     }
}

#Preview("Notification", as: .content, using: FokusWidgetAttributes.preview) {
   FokusWidgetLiveActivity()
} contentStates: {

    FokusWidgetAttributes.ContentState.starEyes
}



struct PomodoroIndicatorForLiveActivity: View {
    
    var timerState: TimerState
    var numberOfPomodoros: Int
    var currentPomodoro: Int
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(0..<numberOfPomodoros, id: \.self) { cycle in
                self.circle(for: cycle)
            }
            Spacer()
        }
    }
    
    private func circle(for cycle: Int) -> AnyView {
        switch timerState {
        case .off,.stopped:
            switch cycle {
            case 0..<currentPomodoro-1:
                return AnyView(StrokedCircleForLiveActivity())
            case currentPomodoro-1:
                return AnyView(StrokedCircleForLiveActivity())
            default:
                return AnyView(StrokedCircleForLiveActivity())
            }
        case .bigBreak, .smallBreak, .bigBreakPaused, .smallBreakPaused:
            switch cycle {
            case 0..<currentPomodoro-1:
                return AnyView(FullCircleForLiveActivity())
            case currentPomodoro-1:
                return AnyView(FullCircleForLiveActivity())
            default:
                return AnyView(StrokedCircleForLiveActivity())
            }
        case .readyToStartPause, .readyToStartFocusTimer:
            switch cycle {
            case 0..<currentPomodoro-1:
                return AnyView(FullCircleForLiveActivity())
            case currentPomodoro-1:
                return AnyView(FullCircleForLiveActivity())
            default:
                return AnyView(StrokedCircleForLiveActivity())
            }
        default:
            switch cycle {
            case 0..<currentPomodoro-1:
                return AnyView(FullCircleForLiveActivity())
            case currentPomodoro-1:
                return AnyView(HalfStrokedCircleForLiveActivity())
            default:
                return AnyView(StrokedCircleForLiveActivity())
            }
        }
    }
}
struct FullCircleForLiveActivity: View {
    var body: some View {
        Circle()
            .fill(Color("textColor"))
            .frame(width: 10, height: 10)
    }
}

struct HalfStrokedCircleForLiveActivity: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("textColor"), lineWidth: 1.0)
                .frame(width: 10, height: 10)
            Circle()
                .trim(from: 0.5, to: 1)
                .fill(Color("textColor"))
                .frame(width: 10, height: 10)
        }
        .rotationEffect(.degrees(270))
    }
}

struct StrokedCircleForLiveActivity: View {
    var body: some View {
        Circle()
            .stroke(Color("textColor"), lineWidth: 1.0)
            .frame(width: 10, height: 10)
    }
}
