//
//  NotificationReminderApp.swift
//  NotificationReminder
//
//  Created by Visalroth on 12/9/25.
//

import SwiftUI

@main
struct NotificationReminderApp: App {
    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
