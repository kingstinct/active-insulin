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

class InsulinInputHostingController: WKHostingController<InsulinInputView> {
  var insulin = Double(AppState.current.insulinInputInitialUnits)
  var isHealthKitAuthorized: HKAuthorizationStatus?
  
  func saveAction(units: Double) -> Void {
    let now = Date.init();
    let sample = HKQuantitySample.init(type: Health.current.insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
                                       metadata: [HKMetadataKeyInsulinDeliveryReason : HKInsulinDeliveryReason.bolus.rawValue]
    )
    Health.current.healthStore.save(sample) { (success, error) in
      
    }
  }
  
  override func didAppear() {
    print("didAppear: InsulinInput")
    checkForAuth()
  }
  
  override func willActivate() {
    print("willActivate: InsulinInput")
    checkForAuth()
  }
  
  override func awake(withContext context: Any?) {
    print("awake: InsulinInput")
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
