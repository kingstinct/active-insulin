//
//  Notifications.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-30.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import HealthKit
import Foundation
import WatchKit
import UserNotifications

class Auth {
  let notificationCenter = UNUserNotificationCenter.current()
  
  static let current = Auth.init();
  
  func requestPermissions(handler: @escaping (_: Bool, _: Bool) -> Void) -> Void {
    Health.current.healthStore.requestAuthorization(toShare: [
      Health.current.insulinQuantityType,
      Health.current.glucoseQuantityType,
    ], read: [
      Health.current.insulinObjectType,
      Health.current.activeEnergyObjectType,
      Health.current.glucoseObjectType,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)!,
      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
    ]) { (success, error) in
      let healthKitSuccess = success;
      
      self.notificationCenter.getNotificationSettings { (settings) in
        let notificationSuccess = settings.alertSetting == .enabled && settings.soundSetting == .enabled;
        if(notificationSuccess){
          handler(healthKitSuccess, notificationSuccess);
        } else {
          self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { (success, error) in
            handler(healthKitSuccess, success);
          }
        }
      }
    }
  }
}
