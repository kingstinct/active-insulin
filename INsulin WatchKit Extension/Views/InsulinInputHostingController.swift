//
//  InsulinInputHostingController.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI
import HealthKit
import Combine
import YOChartImageKit
import Intents

class InsulinInputHostingController: WKHostingController<InsulinInputView> {
  var insulin = Double(AppState.current.insulinInputInitialUnits)
  var isHealthKitAuthorized: HKAuthorizationStatus?
  
  var listenToSelf: AnyCancellable?
  
  func saveAction(units: Double) -> Void {
    let now = Date.init();
    
    let sample = HKQuantitySample.init(type: Health.current.insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
                                       metadata: [HKMetadataKeyInsulinDeliveryReason : HKInsulinDeliveryReason.bolus.rawValue]
    )
    Health.current.healthStore.save(sample) { (success, error) in
      DispatchQueue.main.async {
        if(success){
          if(INPreferences.siriAuthorizationStatus() == .authorized){
            AddInsulinIntent.donate(units: units);
          }
          if(INPreferences.siriAuthorizationStatus() == .notDetermined){
            INPreferences.requestSiriAuthorization { (status) in
              if(status == .authorized){
                AddInsulinIntent.donate(units: units);
              }
            }
          }
        
        
          AppState.current.activePage = .chart
        }
        
      }
    }
  }
  
  
  
  override func didAppear() {
    print("didAppear: InsulinInput")
    checkForAuth()
    if(AppState.current.activePage != .insulinInput) {
      AppState.current.activePage = .insulinInput
    }
  }
  
  override func willActivate() {
    print("willActivate: InsulinInput")
    checkForAuth()
    if(AppState.current.activePage != .insulinInput) {
      AppState.current.activePage = .insulinInput
    }
  }
  
  override func awake(withContext context: Any?) {
    print("awake: InsulinInput")
    listenToSelf = AppState.current.$activePage.sink { (page) in
      if(page == .insulinInput){
        self.becomeCurrentPage()
        self.crownSequencer.focus()
      } else {
        // self.crownSequencer.resignFocus()
      }
    }
  }
  
  func checkForAuth() {
    Health.current.healthStore.getRequestStatusForAuthorization(toShare: [Health.current.insulinQuantityType], read: []) { (status, error) in
      DispatchQueue.main.async {
        if(status == .unnecessary){
          let authStatus = Health.current.healthStore.authorizationStatus(for: Health.current.insulinObjectType);
          self.isHealthKitAuthorized = authStatus;
          self.setNeedsBodyUpdate();
        }
        else if(status == .shouldRequest){
          self.presentAuthAlert { (_, _) in
            self.checkForAuth()
          }
        }
      }
    }
  }
  
  override var body: InsulinInputView {
    return InsulinInputView(saveAction: saveAction, appState: AppState.current, isHealthKitAuthorized: isHealthKitAuthorized)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}
