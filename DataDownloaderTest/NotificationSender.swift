//
//  NotificationSender.swift
//  DataDownloaderTest
//
//  Created by Javier Loucim on 22/07/2018.
//  Copyright © 2018 Qeeptouch. All rights reserved.
//

import Foundation
import UserNotifications

protocol NotificationSender {
    
}

extension NotificationSender {
    func requestPushNotificationAuthorization() {
        let center =  UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (result, error) in
            if error != nil {
                print("\(error!)")
            }
        }
    }
    
    func sendNotification(title:String, subtitle:String, body:String) {
        let center =  UNUserNotificationCenter.current()
        
        //create the content for the notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.default()
        
        //notification trigger can be based on time, calendar or location
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:2.0, repeats: false)
        
        //create request to display
        let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
        
        //add request to notification center
        center.add(request) { (error) in
            if error != nil {
                print("error \(String(describing: error))")
            }
        }
    }
}
