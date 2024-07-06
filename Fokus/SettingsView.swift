//
//  SettingsView.swift
//  Pomodoro
//
//  Created by Andreas Schultz on 22.10.23.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var timer: PomodoroTimer
    
    @State private var timerDuration: Double = 25.0
    @State private var shortBreak: Double = 5.0
    @State private var longBreakDuration: Double = 30.0
    @State private var numberOfPomodoros: Int = 4

    @State private var predefinedPomodoroDuration = [10, 15, 20, 25, 30, 35, 40, 45]
    @State  private var setPomodoroDuration = 25
    @State  private var customPomodoroDuration: Int?
    
    @State private var predefinedShortBreakDuration = [5, 10, 15, 20]
    @State  private var setShortBreakDuration = 5
    @State  private var customShortBreakDuration: Int?
    
    @State private var predefinedLongBreakDuration = [20, 25, 30, 35, 40, 45]
    @State private var setLongBreakDuration = 30
    @State private var customLongBreakDuration: Int?
    
    @State var isNotificationAuthorized = false
    
    @Binding var optionToInterruptFocus: Bool
    @Binding var optionToInterruptBreaks: Bool
    
    var body: some View {
            Form {
                Section(header: Text("Session")) {
                    Group {
                        Picker("Focus Duration:", selection: $setPomodoroDuration) {
                            ForEach(predefinedPomodoroDuration, id: \.self) {
                                Text("\($0) min")
                            }
                            Divider()
                            Text("Custom").tag(0)
                            
                        }
                        if setPomodoroDuration == 0 {
                            HStack {
                                TextField("Enter custom duration", value: $customPomodoroDuration, format: .number)
                                    .keyboardType(.numberPad)
                                if let customPomodoroDuration = customPomodoroDuration {
                                    Button("Set") {
                                        predefinedPomodoroDuration.append(customPomodoroDuration)
                                        setPomodoroDuration = customPomodoroDuration
                                        self.customPomodoroDuration = nil // reset for next selection
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color("backgroundColor"))
                    Group {
                        Picker("Short Break Duration:", selection: $setShortBreakDuration) {
                            ForEach(predefinedShortBreakDuration, id: \.self) {
                                Text("\($0) min")
                            }
                            Divider()
                            Text("Custom").tag(0)
                        }
                        if setShortBreakDuration == 0 {
                            HStack {
                                TextField("Enter custom duration in min", value: $customShortBreakDuration, format: .number)
                                    .keyboardType(.numberPad)
                                if let customShortBreakDuration = customShortBreakDuration {
                                    Button("Set") {
                                        predefinedShortBreakDuration.append(customShortBreakDuration)
                                        setShortBreakDuration = customShortBreakDuration
                                        self.customShortBreakDuration = nil // reset for next selection
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color("backgroundColor"))
                    Group {
                        Picker("Long Break Duration:", selection: $setLongBreakDuration) {
                            ForEach(predefinedLongBreakDuration, id: \.self) {
                                Text("\($0) min")
                            }
                            Divider()
                            Text("Custom").tag(0)
                        }
                        if setLongBreakDuration == 0 {
                            HStack {
                                TextField("Enter custom duration", value: $customLongBreakDuration, format: .number)
                                    .keyboardType(.numberPad)
                                if let customLongBreakDuration = customLongBreakDuration {
                                    Button("Set") {
                                        predefinedLongBreakDuration.append(customLongBreakDuration)
                                        setLongBreakDuration = customLongBreakDuration
                                        self.customLongBreakDuration = nil // reset for next selection
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color("backgroundColor"))
                    Stepper("Focus Cycles: \(numberOfPomodoros)", value: $numberOfPomodoros, in: 1...10, step: 1)
                        .listRowBackground(Color("backgroundColor"))
                    Toggle("Start Focus Automatically", isOn: $timer.startTimerAutomatically)
                        .listRowBackground(Color("backgroundColor"))
                    Toggle("Start Breaks Automatically", isOn: $timer.startPausesAutomatically)
                        .listRowBackground(Color("backgroundColor"))
                }
                Section(header: Text("Notifications")) {
                    Toggle("Notifications", isOn: $timer.notificationsTurnedOn)
                        .disabled(isNotificationAuthorized ? false : true)
                    if !isNotificationAuthorized {
                        Text("No authorization for notifications granted. To grant authorization go to Notifications in your Settings app.")
                            .font(.footnote)
                        Button {
                            Task {
                                await openNotificationsSettings()
                            }
                        } label: {
                            Text("Open Settings")
                        }

                    }
                }
                .listRowBackground(Color("backgroundColor"))
                Section(header: Text("Commitment")) {
                    Toggle("Focus Can Be Interrupted", isOn: $optionToInterruptFocus)
                    Toggle("Breaks Can Be Interrupted", isOn: $optionToInterruptBreaks)
                    //Toggle("Block apps during focus", isOn: $optionToInterrupt)
                }
                .listRowBackground(Color("backgroundColor"))
//                Section(header: Text("Statistics")) {
//                    Text("Export Statistics")
//                    Button("Reset Statistics", role: .destructive) {
//                        print("Reset")
//                    }
//                }
            }
            .navigationTitle("Settings")
            .background(Color("backgroundColor"))
            .scrollContentBackground(.hidden)
        
        .onAppear(perform: {
            let defaults = UserDefaults.standard
            if isKeyPresentInUserDefaults(key: "setPomodoroDuration") {
                self.setPomodoroDuration = defaults.integer(forKey: "setPomodoroDuration")/60
                self.predefinedPomodoroDuration.insert(defaults.integer(forKey: "setPomodoroDuration")/60, at: 0)
            }
            if isKeyPresentInUserDefaults(key: "setLongBreakDuration") {
                self.setLongBreakDuration = defaults.integer(forKey: "setLongBreakDuration")/60
                self.predefinedLongBreakDuration.insert(defaults.integer(forKey: "setLongBreakDuration")/60, at: 0)
            }
            if isKeyPresentInUserDefaults(key: "setShortBreakDuration") {
                self.setShortBreakDuration = defaults.integer(forKey: "setShortBreakDuration")/60
                self.predefinedShortBreakDuration.insert(defaults.integer(forKey: "setShortBreakDuration")/60, at: 0)
            }
            if isKeyPresentInUserDefaults(key: "numberOfPomodoros") {
                self.numberOfPomodoros = defaults.integer(forKey: "numberOfPomodoros")
            }
            if isKeyPresentInUserDefaults(key: "numberOfPomodoros") {
                self.numberOfPomodoros = defaults.integer(forKey: "numberOfPomodoros")
            }
            
            
            self.authorizeStatus { isAuthorized in
                print(isAuthorized)
                self.isNotificationAuthorized = isAuthorized
                if !isAuthorized {
                    timer.notificationsTurnedOn = false
                }
            }
        })
        .onDisappear(perform: {
            
            let defaults = UserDefaults.standard
            
            //Apply changes to Timer Model, save user defaults
            if setPomodoroDuration > 0 {
                timer.setPomodoroDurationInSeconds = setPomodoroDuration*60
                defaults.set(setPomodoroDuration*60, forKey: "setPomodoroDuration")
            }
            if setShortBreakDuration > 0 {
                timer.setShortBreakDurationInSeconds = setShortBreakDuration*60
                defaults.set(setShortBreakDuration*60, forKey: "setShortBreakDuration")
            }
            if setPomodoroDuration > 0 {
                timer.setLongBreakDurationInSeconds = setLongBreakDuration*60
                defaults.set(setLongBreakDuration*60, forKey: "setLongBreakDuration")
            }
            if numberOfPomodoros > 0 {
                timer.numberOfPomodoros = numberOfPomodoros
                defaults.set(numberOfPomodoros, forKey: "numberOfPomodoros")
            }
            
            defaults.setValue(timer.startTimerAutomatically, forKey: "startTimerAutomatically")
            defaults.setValue(timer.startPausesAutomatically, forKey: "startPausesAutomatically")
            
        })
    }
    
    func authorizeStatus(completion: @escaping (_ isAuthorized: Bool) -> Void) {
           let center = UNUserNotificationCenter.current()
           center.getNotificationSettings { (settings) in

               if(settings.authorizationStatus == .authorized) {
                   completion(true)
                   print("Push notification is enabled")
               } else {
                   completion(false)
                   print("Push notification is not enabled")
               }
          }
       }
    
    
    func openNotificationsSettings() async {
        // Create the URL that deep links to your app's notification settings.
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            // Ask the system to open that URL.
            await UIApplication.shared.open(url)
        }
        
        dismiss()
    }
    
}

#Preview {
    SettingsView(timer: PomodoroTimer(), optionToInterruptFocus: .constant(true), optionToInterruptBreaks: .constant(true))
}
