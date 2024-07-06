//
//  Helper.swift
//  Pomodoro
//
//  Created by Andreas Schultz on 22.10.23.
//

import Foundation

func secondsToTimeStamp(seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

func isKeyPresentInUserDefaults(key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

enum TimerState: String {
    case running = "running"
    case focusPaused = "focusPaused"
    case smallBreakPaused = "smallBreakPaused"
    case bigBreakPaused = "bigBreakPaused"
    case stopped = "stopped"
    case off = "off"
    case bigBreak = "bigBreak"
    case smallBreak = "smallBreak"
    case readyToStartFocusTimer = "readyToStartFocusTimer"
    case readyToStartPause = "readyToStartPause"
}

func dateIntervalAndIndexForDate(_ date: Date, in focusIntervals: [DateInterval]) -> (DateInterval, Int)? {
    for (index, interval) in focusIntervals.enumerated() {
        if date >= interval.start && date <= interval.end {
            return (interval, index)
        }
    }
    return nil
}

func calculateRelativePomodoro(absolutePomodoro: Int, numberOfPomodoros: Int) -> Int {
    guard numberOfPomodoros > 0 else {
        fatalError("numberOfPomodoros must be greater than 0")
    }
    
    // Calculate the relative pomodoro based on the absolute pomodoro and numberOfPomodoros
    let relativePomodoro = (absolutePomodoro - 1) % numberOfPomodoros + 1
    
    return relativePomodoro
}

func shiftDateIntervals(_ intervals: [DateInterval], bySeconds seconds: TimeInterval) -> [DateInterval] {
    
    var shiftedIntervals: [DateInterval] = []
    
    for interval in intervals {
        let shiftedStartDate = interval.start.addingTimeInterval(seconds)
        let shiftedEndDate = interval.end.addingTimeInterval(seconds)
        let shiftedInterval = DateInterval(start: shiftedStartDate, duration: shiftedEndDate.timeIntervalSince(shiftedStartDate))
        shiftedIntervals.append(shiftedInterval)
    }
    
    return shiftedIntervals
}

func filterDateIntervals(after currentDate: Date, in dateIntervals: [DateInterval]) -> [DateInterval] {
    return dateIntervals.filter { $0.end > currentDate }
}
