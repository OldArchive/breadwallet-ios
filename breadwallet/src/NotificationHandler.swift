//
//  NotificationHandler.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-07-16.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    
    // received while app is background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("received notification response: \(response)")
        completionHandler()
    }

    // received while app is foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("received notification: \(notification)")
        completionHandler([])
    }
}
