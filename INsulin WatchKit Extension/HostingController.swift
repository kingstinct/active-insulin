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

let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;

class HostingController: WKHostingController<ContentView> {
    var activeInsulin: Double = 0
    let healthStore = HKHealthStore()
    var promise: AnyCancellable?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if(healthStore.authorizationStatus(for: insulinQuantityType) == .sharingAuthorized){
            let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
                self.queryAndUpdateActiveInsulin(handler: handler)
            }
            healthStore.execute(query)
        } else {
            healthStore.requestAuthorization(toShare: [insulinQuantityType], read: [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!]) { (success, error) in
                
                let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
                    self.queryAndUpdateActiveInsulin(handler: handler)
                }
                
                self.healthStore.execute(query)
            }
        }
    }
    
    func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
        if let complications = CLKComplicationServer.sharedInstance().activeComplications {
            for complication in complications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            }
        }
        
        
        
        promise = Calculations.fetchActiveInsulin(healthStore: self.healthStore).sink(receiveCompletion: { (errors) in
            // handle error
            // handler();
        }) { (val) in
            DispatchQueue.main.async {
                self.activeInsulin = val;
                self.setNeedsBodyUpdate()
                handler();
            }
        }
    }
    
    func saveAction(units: Double) -> Void {
        let now = Date.init();
        let sample = HKQuantitySample.init(type: insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
            metadata: [HKMetadataKeyInsulinDeliveryReason : NSNumber.init(value: 2)]
        )
        healthStore.save(sample) { (success, error) in
            
        }
    }
    
    override var body: ContentView {
        return ContentView(activeInsulin: activeInsulin, saveAction: saveAction)
    }
}
