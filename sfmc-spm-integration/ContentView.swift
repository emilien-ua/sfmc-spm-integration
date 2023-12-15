//
//  ContentView.swift
//  sfmc-spm-integration
//
//  Created by Émilien Roussel on 15/12/2023.
//

import SwiftUI

enum NotificationStatus {
    case idle
    case enabled
    case disabled

    var value: String {
        switch self {
        case .idle: "Idle"
        case .enabled: "Enabled"
        case .disabled: "Disabled"
        }
    }

    var color: Color {
        switch self {
        case .idle: .gray
        case .enabled: .green
        case .disabled: .red
        }
    }
}

struct ContentView: View {
    @State private var notificationStatus: NotificationStatus = .idle
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if case .idle = notificationStatus {
                    Text("Fetching remote notification consent...")
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else {
                    Text("Push notification status:")
                        .font(.system(size: 20))
                    Text(notificationStatus.value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(notificationStatus.color)
                }
            }

            if case .disabled = notificationStatus {
                Button("Request push notification consent") {
                    guard let url = URL(string: UIApplication.openNotificationSettingsURLString),
                          UIApplication.shared.canOpenURL(url) else {
                        Logger.print(.contentView, "Unable to access to notification settings URL")
                        return
                    }

                    UIApplication.shared.open(url)
                }
                .padding()
                .foregroundColor(.white)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active: 
                Logger.print(.contentView, "Scene became active")
                handleAPNConsent()
            default: return
            }
        }
        .padding()
    }

    // Mark: - Methods

    func handleAPNConsent() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Logger.print(.contentView, "Notification status: \(settings.authorizationStatus)")

            switch settings.authorizationStatus {
            case .notDetermined: askConsentForAPN()
            case .authorized: notificationStatus = .enabled
            case .denied: notificationStatus = .disabled
            default: return
            }
        }
    }

    func askConsentForAPN() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error {
                    Logger.print(.contentView, "Error while asking consent for APN : \(error)")
                    return
                }

                if granted {
                    DispatchQueue.main.async {
                        Logger.print(.contentView, "Push notification enabled.")
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    Logger.print(.contentView, "Push notification rejected.")
                }

                handleAPNConsent()
            }
    }
}

#Preview {
    ContentView()
}
