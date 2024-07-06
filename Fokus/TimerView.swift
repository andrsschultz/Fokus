//
//  DummyTimerView.swift
//  Pomodoro
//
//  Created by Andreas Schultz on 24.10.23.
//

import SwiftUI

struct TimerView: View {
    
    @ObservedObject var timer: PomodoroTimer
    
    @State private var isPresentingConfirmInterruptFocus: Bool = false
    @State private var isPresentingConfirmInterruptBreak: Bool = false
    
    @State var optionToInterruptFocus = true
    @State var optionToInterruptBreak = true
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                if !timer.notificationsTurnedOn {
                    Text("Notifications disabled.")
                }
                PomodoroIndicator(timer: timer)
                switch timer.timerState {
                case .stopped, .off:
                    Text("Ready to Focus")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.setPomodoroDurationInSeconds))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        timer.startSession()
                    }, label: {
                        Text("Start")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .padding(.bottom, 120)
                case .running:
                    Text("Focusing")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.remainingTimeInSeconds ?? 0))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        self.isPresentingConfirmInterruptFocus = true
                    }, label: {
                        Text("Interrupt Focus")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor").opacity(0.3))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .disabled(optionToInterruptFocus ? false : true)
                    .opacity(optionToInterruptFocus ? 1.0 : 0.0)
                    .padding(.bottom, 120)
                    .confirmationDialog(
                        "Are you sure you want interrupt your focus?",
                        isPresented: $isPresentingConfirmInterruptFocus) {
                            Button("Stop & Reset Focus Time", role: .destructive) {
                                timer.stop()
                            }
                            Button("Pause Focus") {
                                timer.pause(timerStatePaused: .focusPaused)
                            }
                        Button("Cancel", role: .cancel) {
                            isPresentingConfirmInterruptFocus = false
                        }
                    }
                case .focusPaused:
                    Text("Paused")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.remainingTimeInSeconds ?? 0))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        timer.timerState = .running
                        timer.resume()
                    }, label: {
                        Text("Resume Focus")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .padding(.bottom, 120)
                case .bigBreak:
                    Text("Long Break")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.remainingTimeInSeconds ?? 0))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        self.isPresentingConfirmInterruptBreak = true
                    }, label: {
                        Text("Interrupt Break")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .disabled(optionToInterruptBreak ? false : true)
                    .opacity(optionToInterruptBreak ? 1.0 : 0.0)
                    .padding(.bottom, 120)
                    .confirmationDialog(
                        "Are you sure you want interrupt your break?",
                        isPresented: $isPresentingConfirmInterruptBreak) {
                            Button("Stop & Reset Session", role: .destructive) {
                                timer.stop()
                            }
                            Button("Pause Break") {
                                timer.pause(timerStatePaused: .bigBreakPaused)
                            }
                        Button("Cancel", role: .cancel) {
                            self.isPresentingConfirmInterruptBreak = false
                        }
                    }
                case .smallBreak:
                    Text("Short Break")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.remainingTimeInSeconds ?? 0))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        self.isPresentingConfirmInterruptBreak = true
                    }, label: {
                        Text("Interrupt Break")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .disabled(optionToInterruptBreak ? false : true)
                    .opacity(optionToInterruptBreak ? 1.0 : 0.0)
                    .padding(.bottom, 120)
                    .confirmationDialog(
                        "Are you sure you want interrupt your break?",
                        isPresented: $isPresentingConfirmInterruptBreak) {
                            Button("Stop & Reset Session", role: .destructive) {
                                timer.stop()
                            }
                            Button("Pause Break") {
                                timer.pause(timerStatePaused: .smallBreakPaused)
                            }
                        Button("Cancel", role: .cancel) {
                            self.isPresentingConfirmInterruptBreak = false
                        }
                    }
                case .readyToStartPause:
                    Text("Ready for a Break")
                        .padding(.top, 20)
                        .monospaced()
                    Spacer()
                    Button(action: {
                        if timer.currentPomodoro == timer.numberOfPomodoros {
                            timer.remainingTimeInSeconds = timer.setLongBreakDurationInSeconds
                            timer.timerState = .bigBreak
                        } else {
                            timer.remainingTimeInSeconds = timer.setShortBreakDurationInSeconds
                            timer.timerState = .smallBreak
                        }
                        timer.startBreakFromFocus()
                    }, label: {
                        Text("Start")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                        .padding(.bottom, 120)
                case .readyToStartFocusTimer:
                    Text("Ready to  Focus")
                        .padding(.top, 20)
                        .monospaced()
                    Spacer()
                    Button(action: {
                        timer.remainingTimeInSeconds = timer.setPomodoroDurationInSeconds
                        timer.timerState = .running
                        timer.startFocusFromBreak()
                    }, label: {
                        Text("Start")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                        .padding(.bottom, 120)
                case .smallBreakPaused, .bigBreakPaused:
                    Text("Paused")
                        .padding(.top, 20)
                        .monospaced()
                    Text("\(secondsToTimeStamp(seconds: timer.remainingTimeInSeconds ?? 0))")
                        .font(.system(size: 80))
                        .monospaced()
                    Spacer()
                    Button(action: {
                        timer.remainingTimeInSeconds = timer.setPomodoroDurationInSeconds
                        timer.timerState = .running
                        timer.resume()
                    }, label: {
                        Text("Resume Pause")
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                            .background(Color("startButtonColor"))
                            .cornerRadius(10)
                            .monospaced()
                    })
                    .padding(.bottom, 120)
                }

            }
                .background(Color("backgroundColor"))
//                .navigationBarItems(leading:
//                ZStack {
//                    Image(systemName: "music.note.list")
//                        .foregroundStyle(Color("startButtonColor"))
//                        .opacity(0.4)
//                }
//                )
                .navigationBarItems(trailing:
                                        NavigationLink(destination: SettingsView(timer: timer, optionToInterruptFocus: $optionToInterruptFocus, optionToInterruptBreaks: $optionToInterruptBreak), label: {
                    Image(systemName: "gear")
                        .foregroundStyle(Color("startButtonColor"))
                })
                )
                .navigationBarTitleDisplayMode(.large)
        }
        .tint(Color("startButtonColor"))
    }
}

#Preview {
    TimerView(timer: PomodoroTimer()).preferredColorScheme(.dark)
}

struct PomodoroIndicator: View {

    @ObservedObject var timer: PomodoroTimer
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(0..<timer.numberOfPomodoros, id: \.self) { cycle in
                self.circle(for: cycle)
            }
            Spacer()
        }
    }
    
    private func circle(for cycle: Int) -> AnyView {
        switch timer.timerState {
        case .off,.stopped: 
            switch cycle {
            case 0..<timer.currentPomodoro-1:
                return AnyView(StrokedCircle())
            case timer.currentPomodoro-1:
                return AnyView(StrokedCircle())
            default:
                return AnyView(StrokedCircle())
            }
        case .bigBreak, .smallBreak, .bigBreakPaused, .smallBreakPaused:
            switch cycle {
            case 0..<timer.currentPomodoro-1:
                return AnyView(FullCircle())
            case timer.currentPomodoro-1:
                return AnyView(FullCircle())
            default:
                return AnyView(StrokedCircle())
            }
        case .readyToStartPause, .readyToStartFocusTimer:
            switch cycle {
            case 0..<timer.currentPomodoro-1:
                return AnyView(FullCircle())
            case timer.currentPomodoro-1:
                return AnyView(FullCircle())
            default:
                return AnyView(StrokedCircle())
            }
        default:
            switch cycle {
            case 0..<timer.currentPomodoro-1:
                return AnyView(FullCircle())
            case timer.currentPomodoro-1:
                return AnyView(HalfStrokedCircle())
            default:
                return AnyView(StrokedCircle())
            }
        }
    }
}
struct FullCircle: View {
    var body: some View {
        Circle()
            .fill(Color("textColor"))
            .frame(width: 10, height: 10)
    }
}

struct HalfStrokedCircle: View {
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

struct StrokedCircle: View {
    var body: some View {
        Circle()
            .stroke(Color("textColor"), lineWidth: 1.0)
            .frame(width: 10, height: 10)
    }
}
