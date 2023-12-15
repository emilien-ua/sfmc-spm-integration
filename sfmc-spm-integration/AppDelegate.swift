//
//  AppDelegate.swift
//  sfmc-spm-integration
//
//  Created by Émilien Roussel on 15/12/2023.
//

import Foundation
import UIKit
import SFMCSDK
import MarketingCloudSDK

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        initMarketingPush()
        return true
    }
}

extension AppDelegate {
    func initMarketingPush() {
        // TODO: - To replace with accurate values
        let mid = "XXXXXXXXX"
        let appId = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
        let accessToken = "XXXXXXXXXXXXXXXXXXXXXXXX"
        let appEndpoint = "https://XXXXXXXXXXXXXXXXXXXXXXXXXXXX.device.marketingcloudapis.com/"
        let inbox = false
        let location = false
        let analytics = true

        SFMCSdk.setLogger(logLevel: .debug)

        guard let marketingCloudServerUrl = URL(string: appEndpoint) else {
            return
        }

        let mobilePushConfiguration = PushConfigBuilder(appId: appId)
            .setAccessToken(accessToken)
            .setMarketingCloudServerUrl(marketingCloudServerUrl)
            .setMid(mid)
            .setInboxEnabled(inbox)
            .setLocationEnabled(location)
            .setAnalyticsEnabled(analytics)
            .setDelayRegistrationUntilContactKeyIsSet(true)
            .build()

        let completionHandler: (OperationResult) -> Void = { result in
            if result == .success {
                self.setupMobilePush()

                guard let deviceToken = SFMCSdk.mp.deviceToken() else {
                    Logger.print(.appDelegate, "Error: no token - was UIApplication.shared.registerForRemoteNotifications() called?")
                    return
                }

                Logger.print(.appDelegate, "Mobile push token found : \(deviceToken)")
            }
        }

        SFMCSdk.initializeSdk(ConfigBuilder().setPush(config: mobilePushConfiguration, onCompletion: completionHandler).build())
    }

    func setupMobilePush() {
        SFMCSdk.requestPushSdk { mp in
            mp.setURLHandlingDelegate(self)
        }

        SFMCSdk.requestPushSdk { mp in
            mp.setRegistrationCallback { reg in
                mp.unsetRegistrationCallback()
                Logger.print(.appDelegate, "Registration callback was called: \(reg)")
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SFMCSdk.requestPushSdk { mp in
            mp.setDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.print(.appDelegate, "Failed to register for remote notification : \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        SFMCSdk.requestPushSdk { mp in
            mp.setNotificationUserInfo(userInfo)
        }

        completionHandler(.newData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        SFMCSdk.requestPushSdk { mp in
            mp.setNotificationRequest(response.notification.request)
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner])
    }
}

extension AppDelegate: URLHandlingDelegate {
    func sfmc_handleURL(_ url: URL, type: String) {
        UIApplication.shared.open(url) { success in
            Logger.print(.appDelegate, "Opening URL from MarketingCloud notification: (\(success)) | \(url)")
        }
    }
}
