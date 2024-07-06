//
//  PomodoroTimerModel.swift
//  Pomodoro
//
//  Created by Andreas Schultz on 17.12.23.
//

import Foundation
import SwiftUI
import ActivityKit

class PomodoroTimer: ObservableObject {
    
    @MainActor @Published private(set) var activityID: String?
    
    @Published var numberOfPomodoros: Int = 4
    @Published var setPomodoroDurationInSeconds = 25*60
    @Published var setShortBreakDurationInSeconds = 5*60
    @Published var setLongBreakDurationInSeconds = 30*60
    
    var startTimerAutomatically = true
    var startPausesAutomatically = true
    
    @Published var timerState: TimerState = .off
    
    @Published var remainingTimeInSeconds: Int?
    var currrentAbsolutePomodoro = 1
    @Published var currentPomodoro: Int = 1
    
    private var timer: Timer?
    
    var focusDateIntervals = [DateInterval]()
    var smallBreakDateIntervals = [DateInterval]()
    var bigBreakDateIntervals = [DateInterval]()
    
    var dateEnteringBackground: Date?
    var nextTerminationDateWhenEnteringForeground: Date?
    var nextTimerstateWhenEnteringForeground: TimerState?
    
    var dateOfSessionPause: Date?
    
    @Published var notificationsTurnedOn = true
    
    init() {
        retrieveUserDefaults()
        requestNotificationAuth()
    }
    
    func startSession() {
        
        retrieveUserDefaults()
        
        generateTimerIntervals(sessionStartDate: Date())
        
        timerState = .running
        
        remainingTimeInSeconds = setPomodoroDurationInSeconds

        //Make sure not two timers are running at the same time
        timer?.invalidate()
        
        startTimer()

    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            
            let currentDate = Date()
            
            //TBD: currently seconds left are set to +1 , remove if needed
            if let (matchingFocusInterval, index) = dateIntervalAndIndexForDate(currentDate, in: self.focusDateIntervals) {
                self.timerState = .running
                print("current date \(currentDate) falls into running interval")
                let secondsLeft = currentDate.distance(to: matchingFocusInterval.end)
                print("Seconds left: \(secondsLeft)")
                self.remainingTimeInSeconds = Int(secondsLeft+1)
                self.currrentAbsolutePomodoro = index+1
                print("currentAbsolutePomodoro: \(self.currrentAbsolutePomodoro)")
                let currentRelativePomodor = calculateRelativePomodoro(absolutePomodoro: self.currrentAbsolutePomodoro, numberOfPomodoros: self.numberOfPomodoros)
                print("currentRelativePomodor: \(currentRelativePomodor)")
                self.currentPomodoro = currentRelativePomodor
                
                if !startPausesAutomatically && currentDate.addingTimeInterval(1) > matchingFocusInterval.end {
                    print("yolou4j4u3")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        self.timer?.invalidate()
                        self.timerState = .readyToStartPause
                    }
                }
                
            } else if let (matchingSmallBreakInterval, index) = dateIntervalAndIndexForDate(currentDate, in: self.smallBreakDateIntervals) {
                
                self.timerState = .smallBreak
                print("current date \(currentDate) falls into smallBreak interval")
                let secondsLeft = currentDate.distance(to: matchingSmallBreakInterval.end)
                self.currrentAbsolutePomodoro = index+1
                print("currentAbsolutePomodoro: \(self.currrentAbsolutePomodoro)")
                print("Seconds left: \(secondsLeft)")
                self.remainingTimeInSeconds = Int(secondsLeft+1)
                
                if !startTimerAutomatically && currentDate.addingTimeInterval(1) > matchingSmallBreakInterval.end {
                    print("yolou4j4u3")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        self.timer?.invalidate()
                        self.timerState = .readyToStartFocusTimer
                    }
                }
                
                
            } else if let (matchingBigBreakInterval, index) = dateIntervalAndIndexForDate(currentDate, in: self.bigBreakDateIntervals) {
                
                self.timerState = .bigBreak
                print("current date \(currentDate) falls into bigBreak interval")
                let secondsLeft = currentDate.distance(to: matchingBigBreakInterval.end)
                print("Seconds left: \(secondsLeft)")
                self.remainingTimeInSeconds = Int(secondsLeft+1)
                self.currrentAbsolutePomodoro = (index+1)*numberOfPomodoros
                print("currentAbsolutePomodoro: \(self.currrentAbsolutePomodoro)")
                let currentRelativePomodoro = self.numberOfPomodoros
                self.currentPomodoro = self.numberOfPomodoros
                print("currentRelativePomodoro: \(currentRelativePomodoro)")
                
                if !startTimerAutomatically && currentDate.addingTimeInterval(1) > matchingBigBreakInterval.end {
                    print("yolou4j4u3")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        self.timer?.invalidate()
                        self.timerState = .readyToStartFocusTimer
                    }
                }
                
                
            } else {
                print("Error, currentDate \(currentDate) falls into no known date interval.")
                self.timerState = .off
                self.stop()
            }
            
        }
        
    }
    
    func pause(timerStatePaused: TimerState) {
        timer?.invalidate()
        dateOfSessionPause = Date()
        timerState = timerStatePaused
    }
    
    func resume() {
        let currentDate = Date()
        if let dateOfSessionPause = dateOfSessionPause {
            shiftTimerIntervals(bySeconds: currentDate.timeIntervalSince(dateOfSessionPause))
            startTimer()
        } else {
            print("Error when resuming timer.")
            self.timerState = .off
            self.stop()
        }
    }
    
    func stop() {
        timer?.invalidate()
        currentPomodoro = 1
        focusDateIntervals = [DateInterval]()
        smallBreakDateIntervals = [DateInterval]()
        bigBreakDateIntervals = [DateInterval]()
        timerState = .stopped
    }
    
    func startBreakFromFocus() {
        
        if let nextTerminationDateWhenEnteringForeground = nextTerminationDateWhenEnteringForeground {
            let secondsSinceFocusEnded = Date().timeIntervalSince(nextTerminationDateWhenEnteringForeground)
            shiftTimerIntervals(bySeconds: secondsSinceFocusEnded)
        } else {
            let secondsSinceFocusEnded = Date().timeIntervalSince(focusDateIntervals[currrentAbsolutePomodoro-1].end)
            shiftTimerIntervals(bySeconds: secondsSinceFocusEnded)
        }
        
        nextTimerstateWhenEnteringForeground = nil
        nextTerminationDateWhenEnteringForeground = nil
        
        startTimer()
    }
    
    func startFocusFromBreak() {
        if currentPomodoro == numberOfPomodoros {
            print("One")
            let secondsSinceFocusEnded = Date().timeIntervalSince(bigBreakDateIntervals[(currrentAbsolutePomodoro-1)/numberOfPomodoros].end)
            shiftTimerIntervals(bySeconds: secondsSinceFocusEnded)
            startTimer()
        } else {
            print("Two")
            let secondsSinceFocusEnded = Date().timeIntervalSince(smallBreakDateIntervals[currrentAbsolutePomodoro-1].end)
            shiftTimerIntervals(bySeconds: secondsSinceFocusEnded)
            startTimer()
        }
        
        nextTimerstateWhenEnteringForeground = nil
        nextTerminationDateWhenEnteringForeground = nil
    }
    
    func timerEntersBackground() {
        
        dateEnteringBackground = Date()
        
        nextTimerstateWhenEnteringForeground = nil
        nextTerminationDateWhenEnteringForeground = nil
        
        guard timerState == .running ||  timerState == .smallBreak || timerState == .bigBreak else {
            print("No relevant timer state during entering background. Do nothing.")
            return
        }
        
        if !startPausesAutomatically && !startTimerAutomatically {
            if let (matchingFocusInterval, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.focusDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingFocusInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartPause
            } else if let (matchingSmallBreakInterval, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.smallBreakDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingSmallBreakInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartFocusTimer
            } else if let (matchingBigBreakInterval, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.bigBreakDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingBigBreakInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartFocusTimer
            }
            timer?.invalidate()
            
            generateDefiniteNotification()
        } else if !startPausesAutomatically && startTimerAutomatically {
            if let (matchingFocusInterval, _) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.focusDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingFocusInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartPause
            } else if let (matchingSmallBreakInterval, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.smallBreakDateIntervals) {
                nextTerminationDateWhenEnteringForeground = focusDateIntervals[index+1].end
                nextTimerstateWhenEnteringForeground = .readyToStartPause
            } else if let (matchingBigBreakInterval, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.bigBreakDateIntervals) {
                //TBD: Probably bug here
                nextTerminationDateWhenEnteringForeground = focusDateIntervals[(index+1)*numberOfPomodoros].end
                nextTimerstateWhenEnteringForeground = .readyToStartPause
            }
            timer?.invalidate()
            
            generateDefiniteNotification()
        } else if startPausesAutomatically && !startTimerAutomatically {
            if let (_, index) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.focusDateIntervals) {
                nextTerminationDateWhenEnteringForeground = smallBreakDateIntervals[index].end
                nextTimerstateWhenEnteringForeground = .readyToStartFocusTimer
            } else if let (matchingSmallBreakInterval, _) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.smallBreakDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingSmallBreakInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartFocusTimer
            } else if let (matchingBigBreakInterval, _) = dateIntervalAndIndexForDate(dateEnteringBackground!, in: self.bigBreakDateIntervals) {
                nextTerminationDateWhenEnteringForeground = matchingBigBreakInterval.end
                nextTimerstateWhenEnteringForeground = .readyToStartFocusTimer
            }
            timer?.invalidate()
            
            generateDefiniteNotification()
        } else {
            nextTimerstateWhenEnteringForeground = nil
            nextTerminationDateWhenEnteringForeground = nil
            
            
            generateIndefiniteNotifications()
        }
        
        print("Next termination date: \(String(describing: nextTerminationDateWhenEnteringForeground))")
        print("Next termination state: \(String(describing: nextTimerstateWhenEnteringForeground))")
        
//        startLiveActivity()
    }
    
    func timerEntersForeground() {
        
        clearNotifications()
        
//        endActivity()
        
        if nextTimerstateWhenEnteringForeground != nil && nextTerminationDateWhenEnteringForeground != nil {
            if Date() > nextTerminationDateWhenEnteringForeground! {
                timer?.invalidate()
                self.timerState = nextTimerstateWhenEnteringForeground!
            } else {
                startTimer()
            }
        }
        
    }
    
    private func generateDefiniteNotification() {
        
        guard notificationsTurnedOn else {
            print("Notifications are disabled in app.")
            return
        }
        
        guard let nextTimerstateWhenEnteringForeground = nextTimerstateWhenEnteringForeground else { return
            print("1")
        }
        guard let nextTerminationDateWhenEnteringForeground = nextTerminationDateWhenEnteringForeground else { return
            print("2")
        }
        guard let dateEnteringBackground = dateEnteringBackground else { return
            print("3")
        }
        
        print(nextTerminationDateWhenEnteringForeground.timeIntervalSince(dateEnteringBackground))
        
        let content = UNMutableNotificationContent()
        
        if nextTimerstateWhenEnteringForeground == .readyToStartFocusTimer {
            content.title = "Break ended"
            content.subtitle = "Ready to start next focus"
        } else if nextTimerstateWhenEnteringForeground == .readyToStartPause {
            content.title = "Focus ended"
            content.subtitle = "Ready to start break"
        }
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: nextTerminationDateWhenEnteringForeground.timeIntervalSince(dateEnteringBackground), repeats: false)
        
        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
    private func generateIndefiniteNotifications() {
        
        guard notificationsTurnedOn else {
            print("Notifications are disabled in app.")
            return
        }
        
        guard let dateEnteringBackground = dateEnteringBackground else { return
            print("3")
        }
        
        //calculate notifications indefintely (maximum limit is 64 by system)
        //            //How to keep track of curretn pomodoro?
        let filteredFocusDateIntervals = filterDateIntervals(after: dateEnteringBackground, in: focusDateIntervals)
        
        //Calculation is necessary since only 64 notifications are allowed
        let maximumFocusNotifications = 64/2
        let maximiumFocusDateIntervals = Array(filteredFocusDateIntervals.prefix(min(maximumFocusNotifications, filteredFocusDateIntervals.count)))
        print(maximiumFocusDateIntervals.count)
        
        let filteredSmallBreakDateIntervals = filterDateIntervals(after: dateEnteringBackground, in: smallBreakDateIntervals)
        let maximumSmallBreakNotifications = (64/2)*(numberOfPomodoros-1)/numberOfPomodoros
        let maximumSmallBreakDateIntervals = Array(filteredSmallBreakDateIntervals.prefix(min(maximumSmallBreakNotifications, filteredSmallBreakDateIntervals.count)))
        print(maximumSmallBreakDateIntervals.count)
        
        let filteredBigBreakDateIntervals = filterDateIntervals(after: dateEnteringBackground, in: bigBreakDateIntervals)
        let maximumBigBreakNotifications = (64/2)*1/numberOfPomodoros
        let maximumBigBreakDateIntervals = Array(filteredBigBreakDateIntervals.prefix(min(maximumBigBreakNotifications, filteredBigBreakDateIntervals.count)))
        print(maximumBigBreakDateIntervals.count)
        
        print(maximumSmallBreakDateIntervals)
        
        maximiumFocusDateIntervals.enumerated().forEach { (index, focusDateInterval) in
            let content = UNMutableNotificationContent()
            content.title = "Focus Ended"
            //TBD: Differenceiate between small and big break --> now it does only work if we entered background right at the beginnign
            let relativePomodoro = calculateRelativePomodoro(absolutePomodoro: index+1, numberOfPomodoros: numberOfPomodoros)
            if relativePomodoro == numberOfPomodoros {
                content.subtitle = "Starting Big Break"
            } else {
                content.subtitle = "Starting Small Break"
            }
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: focusDateInterval.end.timeIntervalSince(dateEnteringBackground), repeats: false)
            print(focusDateInterval.end.timeIntervalSince(dateEnteringBackground))
            
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
        
        maximumSmallBreakDateIntervals.enumerated().forEach { (index, smallBreakDateInterval) in
            let content = UNMutableNotificationContent()
            content.title = "Small Break Ended"
            content.subtitle = "Starting Focus"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: smallBreakDateInterval.end.timeIntervalSince(dateEnteringBackground), repeats: false)
            
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
        
        maximumBigBreakDateIntervals.enumerated().forEach { (index, bigBreakDateInterval) in
            let content = UNMutableNotificationContent()
            content.title = "Big Break Ended"
            content.subtitle = "Starting Focus"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: bigBreakDateInterval.end.timeIntervalSince(dateEnteringBackground), repeats: false)
            
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
        
        
    }
    
    private func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    private func shiftTimerIntervals(bySeconds: TimeInterval) {
        
        self.focusDateIntervals = shiftDateIntervals(self.focusDateIntervals, bySeconds: bySeconds)
        self.smallBreakDateIntervals = shiftDateIntervals(self.smallBreakDateIntervals, bySeconds: bySeconds)
        self.bigBreakDateIntervals = shiftDateIntervals(self.bigBreakDateIntervals, bySeconds: bySeconds)
        
    }
    
    private func retrieveUserDefaults() {
        //If available, apply User Defaults to model
        let defaults = UserDefaults.standard
        if isKeyPresentInUserDefaults(key: "setPomodoroDuration") {
            self.setPomodoroDurationInSeconds = defaults.integer(forKey: "setPomodoroDuration")
        }
        if isKeyPresentInUserDefaults(key: "setLongBreakDuration") {
            self.setLongBreakDurationInSeconds = defaults.integer(forKey: "setLongBreakDuration")
        }
        if isKeyPresentInUserDefaults(key: "setShortBreakDuration") {
            self.setShortBreakDurationInSeconds = defaults.integer(forKey: "setShortBreakDuration")
        }
        if isKeyPresentInUserDefaults(key: "numberOfPomodoros") {
            self.numberOfPomodoros = defaults.integer(forKey: "numberOfPomodoros")
        }
        if isKeyPresentInUserDefaults(key: "startTimerAutomatically") {
            self.startTimerAutomatically = defaults.bool(forKey: "startTimerAutomatically")
        }
        if isKeyPresentInUserDefaults(key: "startPausesAutomatically") {
            self.startPausesAutomatically = defaults.bool(forKey: "startPausesAutomatically")
        }
        if isKeyPresentInUserDefaults(key: "numberOfPomodoros") {
            self.numberOfPomodoros = defaults.integer(forKey: "numberOfPomodoros")
        }
    }
    
    private func generateTimerIntervals(sessionStartDate: Date) {
        
        var cycleCounter = 1
        
        //Calculate intervals up to one date
        while focusDateIntervals.last?.end ?? sessionStartDate < sessionStartDate.addingTimeInterval(86400) {
            if cycleCounter == 1 {
                if focusDateIntervals.isEmpty {
                    focusDateIntervals.append(DateInterval(start: sessionStartDate, end: sessionStartDate.addingTimeInterval(Double(setPomodoroDurationInSeconds))))
                    smallBreakDateIntervals.append(DateInterval(start: focusDateIntervals.last!.end, end: focusDateIntervals.last!.end.addingTimeInterval(Double(setShortBreakDurationInSeconds))))
                    cycleCounter += 1
                } else {
                    focusDateIntervals.append(DateInterval(start: bigBreakDateIntervals.last!.end, end: bigBreakDateIntervals.last!.end.addingTimeInterval(Double(setPomodoroDurationInSeconds))))
                    smallBreakDateIntervals.append(DateInterval(start: focusDateIntervals.last!.end, end: focusDateIntervals.last!.end.addingTimeInterval(Double(setShortBreakDurationInSeconds))))
                    cycleCounter += 1
                }
            } else if cycleCounter == numberOfPomodoros {
                focusDateIntervals.append(DateInterval(start: smallBreakDateIntervals.last!.end, end: smallBreakDateIntervals.last!.end.addingTimeInterval(Double(setPomodoroDurationInSeconds))))
                bigBreakDateIntervals.append(DateInterval(start: focusDateIntervals.last!.end, end: focusDateIntervals.last!.end.addingTimeInterval(Double(setLongBreakDurationInSeconds))))
                cycleCounter = 1
            } else {
                focusDateIntervals.append(DateInterval(start: smallBreakDateIntervals.last!.end, end: smallBreakDateIntervals.last!.end.addingTimeInterval(Double(setPomodoroDurationInSeconds))))
                smallBreakDateIntervals.append(DateInterval(start: focusDateIntervals.last!.end, end: focusDateIntervals.last!.end.addingTimeInterval(Double(setShortBreakDurationInSeconds))))
                cycleCounter += 1
            }
        
        }
        
    }
    
    private func requestNotificationAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
                self.notificationsTurnedOn = false
            }
        }
    }
    
//    private func startLiveActivity() {
//        Task {
//            print("1")
//            let orderAttributes = FokusWidgetAttributes(name: "Yolo")
//            let initialState = FokusWidgetAttributes.ContentState(secondsRemaining: remainingTimeInSeconds ?? setPomodoroDurationInSeconds, timerState: timerState.rawValue, numberOfPomodoros: numberOfPomodoros, currentPomodoro: currentPomodoro)
//            let content = ActivityContent(state: initialState, staleDate: nil, relevanceScore: 1.0)
//            
//            do {
//                print("2")
//                let orderActivity = try Activity.request(
//                    attributes: orderAttributes,
//                    content: content,
//                    pushType: nil
//                )
//                
//                await MainActor.run { activityID = orderActivity.id }
//                
//            } catch {
//                print(error.localizedDescription)
//            }
//            
//        }
//    }
//    
//    private func endActivity() {
//      Task {
//        guard let activityID = await activityID,
//              let runningActivity = Activity<FokusWidgetAttributes>.activities.first(where: { $0.id == activityID }) else {
//          return
//        }
//
//        let endState = FokusWidgetAttributes.ContentState(secondsRemaining: remainingTimeInSeconds ?? setPomodoroDurationInSeconds, timerState: timerState.rawValue, numberOfPomodoros: numberOfPomodoros, currentPomodoro: currentPomodoro)
//        await runningActivity.end(
//          ActivityContent(state: endState, staleDate: Date.distantFuture),
//          dismissalPolicy: .immediate
//        )
//
//        await MainActor.run { self.activityID = nil }
//      }
//
//    }
    
    
    
}



