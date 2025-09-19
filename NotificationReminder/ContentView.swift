//
//  ContentView.swift
//  NotificationReminder
//
//  Created by Visalroth on 12/9/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var time = Date()                   // pick a time today
    @State private var title = "Drink water"
    @State private var notes = "Stay hydrated 💧"
    @State private var repeats = true
    @State private var timeSensitive = true
    @State private var permissionGranted: Bool? = nil
    @State private var pending: [UNNotificationRequest] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder")) {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Repeat daily", isOn: $repeats)
                    Toggle("Time-Sensitive", isOn: $timeSensitive)
                }

                Section {
                    Button("Allow Notifications") {
                        Task {
                            do {
                                let granted = try await NotificationManager.shared.requestAuthorization()
                                permissionGranted = granted
                            } catch {
                                permissionGranted = false
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Schedule Reminder") {
                        Task {
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                            let hour = comps.hour ?? 9
                            let minute = comps.minute ?? 0
                            do {
                                try await NotificationManager.shared.scheduleReminder(
                                    title: title.isEmpty ? "Reminder" : title,
                                    body: notes.isEmpty ? nil : notes,
                                    hour: hour,
                                    minute: minute,
                                    repeats: repeats,
                                    timeSensitive: timeSensitive
                                )
                                await refreshPending()
                            } catch {
                                print("Schedule error:", error)
                            }
                        }
                    }

                    Button("Cancel All") {
                        NotificationManager.shared.cancelAll()
                        Task { await refreshPending() }
                    }
                    .foregroundColor(.red)
                }

                if let permissionGranted {
                    Section(header: Text("Permission")) {
                        Text(permissionGranted ? "Granted ✅" : "Denied ❌")
                            .foregroundColor(permissionGranted ? .green : .red)
                    }
                }

                Section(header: Text("Pending Reminders")) {
                    if pending.isEmpty {
                        Text("None")
                    } else {
                        ForEach(pending, id: \.identifier) { req in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(req.content.title).bold()
                                if !req.content.body.isEmpty { Text(req.content.body) }
                                if let trig = req.trigger as? UNCalendarNotificationTrigger,
                                   let dc = trig.nextTriggerDate() {
                                    Text("Next: \(dc.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("Repeats: \(((req.trigger as? UNCalendarNotificationTrigger)?.repeats == true) ? "Yes" : "No")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Smooth Reminder")
            .task { await refreshPending() }
        }
    }

    private func refreshPending() async {
        pending = await NotificationManager.shared.pendingRequests()
    }
}
