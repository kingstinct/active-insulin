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
  
  func saveAction(units: Double) -> Void {
    let now = Date.init();
    let sample = HKQuantitySample.init(type: Health.current.insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
                                       metadata: [HKMetadataKeyInsulinDeliveryReason : HKInsulinDeliveryReason.bolus.rawValue]
    )
    Health.current.healthStore.save(sample) { (success, error) in
      
    }
  }
  
  override var body: InsulinInputView {
    return InsulinInputView(saveAction: saveAction, appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}
