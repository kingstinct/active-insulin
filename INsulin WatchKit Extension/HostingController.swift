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

class HostingController: WKHostingController<ContentView> {
    var activeInsulin: Double = 0
    let healthStore = HKHealthStore()
    var promise: AnyCancellable?
    var image: UIImage?
    
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
        
        promise = Calculations.fetchActiveInsulinTimeline(healthStore: self.healthStore, minuteResolution: 5).sink(receiveCompletion: { (errors) in
            // handle error
            // handler();
        }) { (vals) in
            DispatchQueue.main.async {
                if let val = vals.first?.1 {
                    self.activeInsulin = val;
                    self.setNeedsBodyUpdate()
                }
                
                let chart = YOLineChartImage();
                // chart.smooth = true;
                /*let newVals = vals.map({ (_: Date, value: Double) -> NSNumber in
                
                    return NSNumber(value: value);
                })*/
                let newVals = vals.map({ $0.1 })
                chart.values = newVals as [NSNumber];
                chart.fillColor = UIColor.magenta.withAlphaComponent(0.5)
                // chart.smooth = true
                chart.strokeColor = UIColor.magenta
                chart.strokeWidth = 2.0
                
                self.image = chart.draw(CGRect(x: 0, y: 0, width: WKInterfaceDevice.current().screenBounds.width, height: 50), scale: WKInterfaceDevice.current().screenScale);
                
                
                
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
        let optionalData = OptionalData();
        optionalData.chartImage = self.image;
        return ContentView(activeInsulin: activeInsulin, optionalData: optionalData, saveAction: saveAction)
    }
}
