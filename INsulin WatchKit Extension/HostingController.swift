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

class HostingController: WKHostingController<ContentView> {
    var isAuthorized = true;
    
    override func didAppear() {
        Calculations.healthStore.getRequestStatusForAuthorization(toShare: [insulinQuantityType], read: [insulinObjectType]) { (status, error) in
            if(status == .unnecessary){
                self.isAuthorized = true;
            } else {
                self.isAuthorized = false;
            }
            self.setNeedsBodyUpdate()
        }
    }
    
    func saveAction(units: Double) -> Void {
        let now = Date.init();
        let sample = HKQuantitySample.init(type: insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
            metadata: [HKMetadataKeyInsulinDeliveryReason : NSNumber.init(value: 2)]
        )
        Calculations.healthStore.save(sample) { (success, error) in
            
        }
    }
    
    override var body: ContentView {
        return ContentView(saveAction: saveAction, isAuthorized: isAuthorized)
    }
}

struct HostingController_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
