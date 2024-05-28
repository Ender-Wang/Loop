//
//  AppDelegate.swift
//  Loop
//
//  Created by Kai Azim on 2023-10-05.
//

import SwiftUI
import Defaults
import Luminare
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // swiftlint:disable line_length
    static let iconConfiguration = SettingsTab("Icon", Image(systemName: "sparkle"), IconConfigurationView())
    static let accentColorConfiguration = SettingsTab("Accent Color", Image(systemName: "paintbrush.pointed"), AccentColorConfigurationView())
    static let radialMenuConfiguration = SettingsTab("Radial Menu", Image("loop"), RadialMenuConfigurationView())
    static let previewConfiguration = SettingsTab("Preview", Image(systemName: "rectangle.lefthalf.inset.filled"), PreviewConfigurationView())

    static let behaviorConfiguration = SettingsTab("Behavior", Image(systemName: "gear"), BehaviorConfigurationView())
    static let keybindingsConfiguration = SettingsTab("Keybindings", Image(systemName: "command"), KeybindingsConfigurationView())

    static let advancedConfiguration = SettingsTab("Advanced", Image(systemName: "face.smiling.inverse"), AdvancedConfigurationView())
    static let excludedAppsConfiguration = SettingsTab("Excluded Apps", Image(systemName: "lock.app.dashed"), ExcludedAppsConfigurationView())
    static let aboutConfiguration = SettingsTab("About", Image(systemName: "ellipsis"), AboutConfigurationView())
    // swiftlint:enable line_length

    static var luminare = LuminareSettingsWindow(
        [
            .init("Theming", [
                iconConfiguration,
                accentColorConfiguration,
                radialMenuConfiguration,
                previewConfiguration
            ]),
            .init("Settings", [
                behaviorConfiguration,
                keybindingsConfiguration
            ]),
            .init("Loop", [
                advancedConfiguration,
                excludedAppsConfiguration,
                aboutConfiguration
            ])
        ],
        tint: { Color.getLoopAccent(tone: .normal) },
        didTabChange: processTabChange
    )

    private static func processTabChange(_ tab: SettingsTab? = nil) {
        let activePreviews = luminare.previewViews

        if tab == radialMenuConfiguration || tab == nil {
            if !activePreviews.contains("RadialMenu") {
                luminare.addPreview(content: RadialMenuView(previewMode: true), identifier: "RadialMenu")
            }
            return
        }
        if tab == previewConfiguration {
            luminare.removePreview(identifier: "RadialMenu")
            return
        }
    }

    private let loopManager = LoopManager()
    private let windowDragManager = WindowDragManager()

    private var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else { return false }
        return
            event.eventID == kAEOpenApplication &&
            event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApp.setActivationPolicy(.accessory)

        // Check & ask for accessibility access
        AccessibilityManager.requestAccess()
        UNUserNotificationCenter.current().delegate = self

        AppDelegate.requestNotificationAuthorization()

        IconManager.refreshCurrentAppIcon()
        loopManager.startObservingKeys()
        windowDragManager.addObservers()

        if !self.launchedAsLoginItem {
            AppDelegate.openSettings()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//        NSApp.setActivationPolicy(.accessory)
        for window in NSApp.windows where window.delegate != nil {
            window.delegate = nil
        }
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppDelegate.openSettings()
        return true
    }

    // Mostly taken from https://github.com/Wouter01/SwiftUI-WindowManagement
    static func openSettings() {
        luminare.show()
        processTabChange()
    }

    // ----------
    // MARK: - Notifications
    // ----------

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "setIconAction",
           let icon = response.notification.request.content.userInfo["icon"] as? String {
            IconManager.setAppIcon(to: icon)
        }

        completionHandler()
    }

    // Implementation is necessary to show notifications even when the app has focus!
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }

    static func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert]
        ) { accepted, error in
            if !accepted {
                print("User Notification access denied.")
            }

            if let error = error {
                print(error)
            }
        }
    }

    private static func registerNotificationCategories() {
        let setIconAction = UNNotificationAction(
            identifier: "setIconAction",
            title: .init(localized: .init("Notification/Set Icon: Action", defaultValue: "Set Current Icon")),
            options: .destructive
        )
        let notificationCategory = UNNotificationCategory(
            identifier: "icon_unlocked",
            actions: [setIconAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
    }

    static func areNotificationsEnabled() -> Bool {
        let group = DispatchGroup()
        group.enter()

        var notificationsEnabled = false

        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            notificationsEnabled = notificationSettings.authorizationStatus != UNAuthorizationStatus.denied
            group.leave()
        }

        group.wait()
        return notificationsEnabled
    }

    static func sendNotification(_ content: UNMutableNotificationContent) {
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: uuidString,
            content: content,
            trigger: nil
        )

        requestNotificationAuthorization()
        registerNotificationCategories()

        UNUserNotificationCenter.current().add(request)
    }

    static func sendNotification(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.categoryIdentifier = UUID().uuidString

        AppDelegate.sendNotification(content)
    }
}
