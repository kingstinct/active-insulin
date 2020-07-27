//
//  HostingController.swift
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

let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
let insulinObjectType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;

class InsulinInputHostingController: WKHostingController<InsulinInputView> {
  override func didAppear() {
  }
  
  func saveAction(units: Double) -> Void {
    let now = Date.init();
    let sample = HKQuantitySample.init(type: insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
                                       metadata: [HKMetadataKeyInsulinDeliveryReason : HKInsulinDeliveryReason.bolus.rawValue]
    )
    Health.current.healthStore.save(sample) { (success, error) in
      
    }
  }
  
  override var body: InsulinInputView {
    let appState = AppState.current();
    return InsulinInputView(saveAction: saveAction, appState: appState)
  }
}

struct HostingController_Previews: PreviewProvider {
  static var previews: some View {
    InsulinInputView(appState: AppState.current())
  }
}


