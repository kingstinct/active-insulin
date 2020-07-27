//
//  Calculations.swift
//  INsulin WatchKit Extension
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

class Health {
  let healthStore = HKHealthStore()
  
  static let current = Health();
  
  func filterBolusSample(sample: HKQuantitySample) -> Bool{
    return nil != sample.metadata?.first(where: { (pair) -> Bool in
      if(pair.key == HKMetadataKeyInsulinDeliveryReason){
        if let value = pair.value as? Int {
          let deliveryReason = HKInsulinDeliveryReason.init(rawValue: value)
          return deliveryReason == HKInsulinDeliveryReason.bolus;
        }
      }
      return false;
    }) // ?.index(forKey: HKMetadataKeyInsulinDeliveryReason) == HKInsulinDeliveryReason.basal
  }
  
  func fetchActiveInsulin(callback: @escaping (Error?, Double?) -> Void, forTime: Date? = nil) -> Void {
    let dateTime = forTime ?? Date();
    // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
    let from = dateTime.advanced(by: TimeInterval(exactly: -AppState.current.totalDurationInMinutes * 60)!);
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: from, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, nil)
      } else {
        if let samples = _samples as? [HKQuantitySample] {
          var totalActiveInsulinLeft: Double = 0;
          
          for sample in samples.filter(self.filterBolusSample) {
            let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
            let minutesAgo = -sample.startDate.timeIntervalSince(dateTime) / 60;
            if(minutesAgo <= AppState.current.totalDurationInMinutes){
              let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: AppState.current.peakTimeInMinutes, totalDurationInMinutes: AppState.current.totalDurationInMinutes);
              let activeInsulinLeft = quantity * iobFactor;
              totalActiveInsulinLeft += activeInsulinLeft;
            }
          }
          
          DispatchQueue.main.async {
            callback(nil, totalActiveInsulinLeft)
          }
        }
      }
    }
    
    healthStore.execute(query);
    
  }
  
  
  
  func fetchActiveInsulinTimeline(from: Date, to: Date, callback: @escaping (Error?, Array<(Date, Double)>?) -> Void, minuteResolution: Double = 5) -> Void {
    // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
    let queryFrom = from.advanced(by: TimeInterval(exactly: -AppState.current.totalDurationInMinutes * 60)!);
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, nil)
      } else {
        if let unfilteredSamples = _samples as? [HKQuantitySample] {
          let samples = unfilteredSamples.filter(self.filterBolusSample);
          var futureMinute: Double = 0;
          var retVal = Array<(Date, Double)>();
          while(futureMinute <= to.timeIntervalSince(from) / 60){
            let date = from.advanced(by: TimeInterval(futureMinute * 60))
            var totalActiveInsulinLeft: Double = 0;
            for sample in samples {
              let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
              let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
              // if(minutesAgo <= totalDurationInMinutes && minutesAgo >= 0){
              let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: AppState.current.peakTimeInMinutes, totalDurationInMinutes: AppState.current.totalDurationInMinutes);
              let activeInsulinLeft = quantity * iobFactor;
              totalActiveInsulinLeft += activeInsulinLeft;
              // }
            }
            
            retVal.append((date, totalActiveInsulinLeft))
            
            futureMinute += minuteResolution;
          }
          
          
          DispatchQueue.main.async {
            callback(nil, retVal)
          }
        }
      }
    }
    
    healthStore.execute(query);
    
  }
  
  
  func fetchActiveInsulinChart(from: Date, to: Date, minuteResolution: Double = 2) -> Future<[(Date, Double)], Error>{
    return Future { promise in
      // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
      let queryFrom = from.advanced(by: TimeInterval(exactly: -AppState.current.totalDurationInMinutes * 60)!);
      
      let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
        if let e = error {
          promise(.failure(e));
        } else {
          if let unfilteredSamples = _samples as? [HKQuantitySample] {
            let samples = unfilteredSamples.filter(self.filterBolusSample);
            var futureMinute: Double = 0;
            var retVal = Array<(Date, Double)>();
            while(futureMinute <= to.timeIntervalSince(from) / 60){
              let date = from.advanced(by: TimeInterval(futureMinute * 60))
              var totalActiveInsulinLeft: Double = 0;
              for sample in samples {
                let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
                let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
                if(minutesAgo <= AppState.current.totalDurationInMinutes && minutesAgo >= 0){
                  let activityRightNow = -Calculations.insulinActivityCurve(t: minutesAgo, peakTimeInMinutes: AppState.current.peakTimeInMinutes, totalDurationInMinutes: AppState.current.totalDurationInMinutes);
                  // print(activityRightNow)
                  let activeInsulinLeft = quantity * activityRightNow;
                  totalActiveInsulinLeft += activeInsulinLeft > 0 ? activeInsulinLeft : 0;
                }
              }
              
              retVal.append((date, totalActiveInsulinLeft))
              
              futureMinute += minuteResolution;
            }
            
            
            DispatchQueue.main.async {
              promise(.success(retVal));
            }
          }
        }
      }
      
      self.healthStore.execute(query);
    }
    
  }
}

