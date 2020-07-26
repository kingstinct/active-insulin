//
//  ExtensionDelegate.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import WatchKit
import UserNotifications
import HealthKit;
import Combine;

class ExtensionDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {
    let healthStore = HKHealthStore();
    let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
    var promise: AnyCancellable?
    

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self;
        // Define the custom actions.
        let snooze15 = UNNotificationAction(identifier: "SNOOZE_15",
              title: "Snooze 15 mins",
              options: [])
        let snooze30 = UNNotificationAction(identifier: "SNOOZE_30",
              title: "Snooze 30 mins",
              options: [])
        let snooze60 = UNNotificationAction(identifier: "SNOOZE_60",
        title: "Snooze 1 hour",
        options: [])
        // Define the notification type
        let meetingInviteCategory = UNNotificationCategory(identifier: "PEAK", actions: [snooze15, snooze30, snooze60], intentIdentifiers: [], options: [.allowAnnouncement, .allowInCarPlay])
        
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([meetingInviteCategory])
        
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (success, error) in
            
        }
        
        
        if(healthStore.authorizationStatus(for: insulinQuantityType) == .sharingAuthorized){
            let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
                self.onUpdatedInsulin(completionHandler: handler)
            }
            healthStore.execute(query)
        } else {
            healthStore.requestAuthorization(toShare: [insulinQuantityType], read: [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!]) { (success, error) in
                
                let query = HKObserverQuery.init(sampleType: self.insulinQuantityType, predicate: nil) { (query, handler, error) in
                    self.onUpdatedInsulin(completionHandler: handler)
                }
                
                self.healthStore.execute(query)
            }
        }
    }
    
    func onUpdatedInsulin(completionHandler: @escaping () -> Void){
        if let complications = CLKComplicationServer.sharedInstance().activeComplications {
            for complication in complications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            }
        }
        
        promise = Calculations.fetchActiveInsulinChart(healthStore: self.healthStore, from: Date().advanced(by: TimeInterval(-60 * 60)), to: Date().advanced(by: TimeInterval(5 * 60 * 60))).sink(receiveCompletion: { (errors) in
            // handle error
            // handler();
        }) { (vals) in
            DispatchQueue.main.async {
                if let max = vals.max { (arg0, arg1) -> Bool in
                    return arg0.1 < arg1.1;
                    } {
                    
                    let content = UNMutableNotificationContent();
                    content.body = "Your insulin level is peaking, check your glucose?";
                    content.title = "Insulin Peak";
                    content.categoryIdentifier = "PEAK";
                    let dateMatching = Calendar.current.dateComponents([.minute, .day, .hour], from: max.0)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
                    UNUserNotificationCenter.current().add(UNNotificationRequest.init(identifier: "PEAK", content: content, trigger: trigger)) { (error) in
                        //something failed
                    }
                }
                completionHandler();
            }
            
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = UNMutableNotificationContent();
        content.body = "Time to check your glucose after your insulin peak?";
        content.title = "Insulin Reminder";
        content.categoryIdentifier = "PEAK";
        
        if(response.actionIdentifier == "SNOOZE_15"){
            let dateMatching = Calendar.current.dateComponents([.minute, .day, .hour], from: Date.init(timeIntervalSinceNow: TimeInterval(60 * 15)))
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
            
            UNUserNotificationCenter.current().add(UNNotificationRequest.init(identifier: "SNOOZE", content: content, trigger: trigger)) { (error) in
                //something failed
            }
        }
        else if(response.actionIdentifier == "SNOOZE_30"){
            let dateMatching = Calendar.current.dateComponents([.minute, .day, .hour], from: Date.init(timeIntervalSinceNow: TimeInterval(60 * 30)))
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
            
            UNUserNotificationCenter.current().add(UNNotificationRequest.init(identifier: "SNOOZE", content: content, trigger: trigger)) { (error) in
                //something failed
            }
        }
        else if(response.actionIdentifier == "SNOOZE_60"){
            let dateMatching = Calendar.current.dateComponents([.minute, .day, .hour], from: Date.init(timeIntervalSinceNow: TimeInterval(60 * 30)))
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateMatching, repeats: false)
            
            UNUserNotificationCenter.current().add(UNNotificationRequest.init(identifier: "SNOOZE", content: content, trigger: trigger)) { (error) in
                //something failed
            }
        }
        completionHandler();
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
