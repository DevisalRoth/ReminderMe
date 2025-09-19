//
//  Untitled.swift
//  NotificationReminder
//
//  Created by Visalroth on 12/9/25.
//


import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    // MARK: - Setup
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
    }

    // MARK: - Scheduling
    /// Schedules a one-time or repeating reminder at a specific hour+minute (local time).
    func scheduleReminder(
        identifier: String = UUID().uuidString,
        title: String,
        body: String? = nil,
        hour: Int,
        minute: Int,
        repeats: Bool = false,
        timeSensitive: Bool = true,
        sound: UNNotificationSound = .default
    ) async throws {
        // Content
        let content = UNMutableNotificationContent()
        content.title = title
        if let body { content.body = body }
        content.sound = sound

        if #available(iOS 15.0, *), timeSensitive {
            content.interruptionLevel = .timeSensitive
        }

        // Trigger: let the system handle DST/time zone changes
        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: repeats)

        // Request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
                cont.resume(returning: reqs)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Show alerts even when app is foregrounded (optional)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        return [.banner, .sound, .list]
    }
}
