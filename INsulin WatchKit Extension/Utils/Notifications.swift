//
//  Notifications.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-30.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
import WatchKit
import UserNotifications

class Auth {
  func requestPermissions(handler: @escaping (healthkitSuccess: Bool, notificationSuccess: Bool) -> Void){
    var healthKitSuccess: Bool;
    var notificationSuccess: Bool;
    WKAlertAction.init(title: "Allow", style: WKAlertActionStyle.default, handler: {
      Health.current.healthStore.requestAuthorization(toShare: [Health.current.insulinQuantityType], read: [Health.current.insulinObjectType, Health.current.activeEnergyObjectType]) { (success, error) in
        healthKitSuccess = success;
      }
      let notificationCenter = UNUserNotificationCenter.current()
      notificationCenter.getNotificationSettings { (settings) in
        if(settings.alertSetting == .enabled && settings.soundSetting == .enabled){
          notificationSuccess = true;
        } else {
          notificationCenter.requestAuthorization(options: [.alert, .sound]) { (success, error) in
            notificationSuccess = success;
          }
        }
      }
    })
    ])
  }
}
