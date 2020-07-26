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
import UserNotifications


class ChartHostingController: WKHostingController<ChartView> {
    let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
    var activeInsulin: Double = 0
    let healthStore = HKHealthStore()
    var promise: AnyCancellable?
    var anotherPromise: AnyCancellable?
    var image: UIImage?
    
    var isAuthorized = true;
    
    override func awake(withContext context: Any?) {
        let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
            self.queryAndUpdateActiveInsulin(handler: handler)
        }
        healthStore.execute(query)
    }
    
    override func didAppear() {
        healthStore.getRequestStatusForAuthorization(toShare: [insulinQuantityType], read: [insulinObjectType]) { (status, error) in
            if(status == .unnecessary){
                self.isAuthorized = true;
            } else {
                self.isAuthorized = false;
            }
            self.setNeedsBodyUpdate()
        }
    }
    
    func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
        anotherPromise = Calculations.fetchActiveInsulin(healthStore: self.healthStore).sink(receiveCompletion: { (error) in
            
        }, receiveValue: { (value) in
            self.activeInsulin = value
        })
        
        promise = Calculations.fetchActiveInsulinChart(healthStore: self.healthStore, from: Date().advanced(by: TimeInterval(-60 * 60)), to: Date().advanced(by: TimeInterval(5 * 60 * 60))).sink(receiveCompletion: { (errors) in
            // handle error
            // handler();
        }) { (vals) in
            DispatchQueue.main.async {
                let newImage = Calculations.getChartImage(vals: vals);
                    
                self.image = newImage
                
                self.setNeedsBodyUpdate()
            }
            
            handler();
        }
    }
    
    override var body: ChartView {
        let optionalData = OptionalData();
        optionalData.chartImage = self.image;
        return ChartView(activeInsulin: activeInsulin, isAuthorized: isAuthorized, optionalData: optionalData)
    }
}

struct ChartHostingController_Previews: PreviewProvider {
    static var previews: some View {
        let optionalData = OptionalData();
        return ChartView(activeInsulin: 5, optionalData: optionalData)
    }
}
