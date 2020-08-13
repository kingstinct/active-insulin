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

struct Injection {
  var date: Date;
  var insulinUnits: Double;
  var quantitySample: HKQuantitySample?;
}

struct ChartPoint: Equatable {
  var date: Date;
  var insulinOnBoard: Double;
  var currentInsulin: Double;
}

struct StatsResponse {
  // var averageQuantity: Double?;
  
  var maximumQuantity: Double?;
  // var minimumQuantity: Double?;
  var mostRecentQuantity: Double?;
  var mostRecentTime: Date?;
  var sumQuantity: Double?;
  var startDate: Date;
  var endDate: Date;
  var totalDays: Double?;
}

class Health {
  let healthStore = HKHealthStore()
  let glucoseQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!;
    let glucoseObjectType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!;
  let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
  let activeEnergyQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!;
  let insulinObjectType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
  let activeEnergyObjectType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!;
  
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
  
  func iobFromValues(forTime: Date = Date(), injections: Array<Injection>) -> Double {
    return injections.reduce(0) { (acc, injection) -> Double in
      let minutesAgo = -injection.date.timeIntervalSince(forTime) / 60;
      if(minutesAgo <= Double(AppState.current.insulinDurationInMinutes)){
        let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: Double(AppState.current.insulinPeakTimeInMinutes), totalDurationInMinutes: Double(AppState.current.insulinDurationInMinutes));
        let activeInsulinLeft = injection.insulinUnits * iobFactor;
        return activeInsulinLeft + acc;
      }
      return acc;
    }
  }
  
  func deleteSample(sample: HKQuantitySample, callback: @escaping (_ error: Error?) -> Void) -> Void {
    healthStore.delete(sample) { (success, error) in
      callback(error);
    }
  }
  
  func fetchIOB(forTime: Date = Date(), callback: @escaping (Error?, Double?) -> Void) -> Void {
    
    let from = forTime.addMinutes(addMinutes: -Double(AppState.current.insulinDurationInMinutes));
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: from, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, nil)
      } else {
        if let samples = _samples as? [HKQuantitySample] {
          let injections = samples.filter(self.filterBolusSample).map { (sample) -> Injection in
            return Injection(date: sample.startDate, insulinUnits: sample.quantity.doubleValue(for: HKUnit.internationalUnit()), quantitySample: sample);
          }
          
          let totalActiveInsulinLeft = self.iobFromValues(forTime: forTime, injections: injections);
          
          DispatchQueue.main.async {
            callback(nil, totalActiveInsulinLeft)
          }
        }
      }
    }
    
    healthStore.execute(query);
    
  }
  
  
  /*func fetchActiveInsulinTimelineSmart(from: Date, to: Date, callback: @escaping (Error?, Array<(Date, Double)>?) -> Void) -> Void {
   // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
   let queryFrom = from.advanced(by: TimeInterval(exactly: -AppState.current.totalDurationInMinutes * 60)!);
   let minuteResolution = 2.0; // for complications this is the highest allowed resolution
   
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
   
   let roundedInsulinLeft = Double(round(totalActiveInsulinLeft * 10)) / 10.0;
   
   if let previous = retVal.last {
   if(roundedInsulinLeft != previous.1){
   retVal.append((date, roundedInsulinLeft));
   }
   } else {
   retVal.append((date, roundedInsulinLeft))
   }
   
   
   futureMinute += minuteResolution;
   }
   
   
   DispatchQueue.main.async {
   callback(nil, retVal)
   }
   }
   }
   }
   
   healthStore.execute(query);
   
   }*/
  
  
  func fetchInsulinStats(start: Date, end: Date = Date(), callback: @escaping (Error?, StatsResponse?) -> Void) {
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: []);
    
    let query = HKStatisticsQuery.init(quantityType: insulinQuantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum, .mostRecent, .duration /*.discreteMax*/]) { (_, stats, error) in
      if let stats = stats {
        let totalDays = stats.startDate.distance(to: stats.endDate) / (60 * 60 * 24)
        return callback(
          nil,
          StatsResponse(
            // averageQuantity: stats.averageQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            // maximumQuantity: stats.maximumQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            //minimumQuantity: stats.minimumQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            mostRecentQuantity: stats.mostRecentQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            mostRecentTime: stats.mostRecentQuantityDateInterval()?.start,
            sumQuantity: stats.sumQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            startDate: stats.startDate,
            endDate: stats.endDate,
            totalDays: totalDays
          )
        )
      }
      else {
        callback(error, nil);
      }
    }
    healthStore.execute(query);
  }
  
  func fetchActiveEnergyStats(start: Date, end: Date? = nil, callback: @escaping (Error?, StatsResponse?) -> Void) {
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: []);
    
    let query = HKStatisticsQuery.init(quantityType: activeEnergyQuantityType, quantitySamplePredicate: predicate, options: [.cumulativeSum, .mostRecent, .duration]) { (_, stats, error) in
      if let stats = stats {
        let totalDays = stats.startDate.distance(to: stats.endDate) / (60 * 60 * 24)
        return callback(
          nil,
          StatsResponse(
            // averageQuantity: stats.averageQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            // maximumQuantity: stats.maximumQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            //minimumQuantity: stats.minimumQuantity()?.doubleValue(for: HKUnit.internationalUnit()),
            mostRecentQuantity: stats.mostRecentQuantity()?.doubleValue(for: HKUnit.kilocalorie()),
            mostRecentTime: stats.mostRecentQuantityDateInterval()?.start,
            sumQuantity: stats.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()),
            startDate: stats.startDate,
            endDate: stats.endDate,
            totalDays: totalDays
          )
        )
      }
      else {
        callback(error, nil);
      }
    }
    healthStore.execute(query);
  }
  
  func fetchInjections(from: Date, to: Date = Date(), callback: @escaping (Error?, Array<Injection>?) -> Void) {
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: from, end: to, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, nil)
      } else {
        if let unfilteredSamples = _samples as? [HKQuantitySample] {
          let samples = unfilteredSamples.filter(self.filterBolusSample)
            .map { (sample) -> Injection in
              return Injection(date: sample.startDate, insulinUnits: sample.quantity.doubleValue(for: HKUnit.internationalUnit()), quantitySample: sample)
          }
          callback(nil, samples)
        }
      }
    }
    
    healthStore.execute(query);
  }
  
  func fetchTimelineIOB(from: Date = Date(), limit: Int = 100, callback: @escaping (Error?, Array<(Date, Double)>?) -> Void) -> Void {
    // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
    let queryFrom = from.addMinutes(addMinutes: -AppState.current.insulinDurationInMinutes);
    let minuteResolution = 2.0; // for complications this is the highest allowed resolution
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, nil)
      } else {
        if let unfilteredSamples = _samples as? [HKQuantitySample] {
          let samples = unfilteredSamples.filter(self.filterBolusSample);
          var futureMinute: Double = 0;
          var retVal = Array<(Date, Double)>();
          while(retVal.count < limit){
            let date = from.addMinutes(addMinutes: futureMinute);
            var totalActiveInsulinLeft: Double = 0;
            for sample in samples {
              let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
              let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
              // if(minutesAgo <= totalDurationInMinutes && minutesAgo >= 0){
              let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: Double(AppState.current.insulinPeakTimeInMinutes), totalDurationInMinutes: AppState.current.insulinDurationInMinutes);
              let activeInsulinLeft = quantity * iobFactor;
              totalActiveInsulinLeft += activeInsulinLeft;
              // }
            }
            
            let roundedInsulinLeft = Double(round(totalActiveInsulinLeft * 10)) / 10.0;
            
            if let previous = retVal.last {
              if(roundedInsulinLeft != previous.1){
                retVal.append((date, roundedInsulinLeft));
              }
            } else {
              retVal.append((date, roundedInsulinLeft))
            }
            
            if(roundedInsulinLeft == 0){
              break;
            }
            
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
  
  
  /*func fetchActiveInsulinTimeline(from: Date, to: Date, minuteResolution: Double = 5, callback: @escaping (Error?, Array<(Date, Double)>?) -> Void) -> Void {
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
   
   }*/
  
  func buildChartData (injections: Array<Injection>, from: Date, to: Date, minuteResolution: Double) -> Array<ChartPoint> {
    var futureMinute: Double = 0;
    var retVal = Array<ChartPoint>();
    while(futureMinute <= to.timeIntervalSince(from) / 60){
      let date = from.advanced(by: TimeInterval(futureMinute * 60))
      var insulinOnBoard: Double = 0;
      var currentInsulin: Double = 0;
      
      for injection in injections {
        let minutesAgo = -injection.date.timeIntervalSince(date) / 60;
        if(minutesAgo <= Double(AppState.current.insulinDurationInMinutes) && minutesAgo >= 0){
          let activityRightNow = -Calculations.insulinActivityCurve(t: minutesAgo, peakTimeInMinutes: Double(AppState.current.insulinPeakTimeInMinutes), totalDurationInMinutes: Double(AppState.current.insulinDurationInMinutes));
          
          let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: Double(AppState.current.insulinPeakTimeInMinutes), totalDurationInMinutes: Double(AppState.current.insulinDurationInMinutes));
          let iob = injection.insulinUnits * iobFactor;
          insulinOnBoard += iob;
          
          let activeInsulinLeft = injection.insulinUnits * activityRightNow;
          currentInsulin += activeInsulinLeft > 0 ? activeInsulinLeft : 0;
        }
      }
      
      retVal.append(ChartPoint(date: date, insulinOnBoard: insulinOnBoard, currentInsulin: currentInsulin))
      
      futureMinute += minuteResolution;
    }
    return retVal;
  }
  
  func fetchActiveInsulinChart(from: Date, to: Date, minuteResolution: Double = 2, callback: @escaping (Error?, Array<ChartPoint>) -> Void) -> Void {
    
    // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
    let queryFrom = from.addMinutes(addMinutes: -Double(AppState.current.insulinDurationInMinutes))
    
    let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
      if let e = error {
        callback(e, []);
      } else {
        if let unfilteredSamples = _samples as? [HKQuantitySample] {
          let samples = unfilteredSamples.filter(self.filterBolusSample).map { (sample) -> Injection in
            return Injection(date: sample.startDate, insulinUnits: sample.quantity.doubleValue(for: HKUnit.internationalUnit()), quantitySample: sample)
          };
          let retVal = self.buildChartData(injections: samples, from: from, to: to, minuteResolution: minuteResolution)
          /*var futureMinute: Double = 0;
           var retVal = Array<ChartPoint>();
           while(futureMinute <= to.timeIntervalSince(from) / 60){
           let date = from.advanced(by: TimeInterval(futureMinute * 60))
           var insulinOnBoard: Double = 0;
           var currentInsulin: Double = 0;
           for sample in samples {
           let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
           let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
           if(minutesAgo <= AppState.current.totalDurationInMinutes && minutesAgo >= 0){
           let activityRightNow = -Calculations.insulinActivityCurve(t: minutesAgo, peakTimeInMinutes: AppState.current.peakTimeInMinutes, totalDurationInMinutes: AppState.current.totalDurationInMinutes);
           
           let iobFactor = Calculations.iobCurve(t: minutesAgo, peakTimeInMinutes: AppState.current.peakTimeInMinutes, totalDurationInMinutes: AppState.current.totalDurationInMinutes);
           let iob = quantity * iobFactor;
           insulinOnBoard += iob;
           
           let activeInsulinLeft = quantity * activityRightNow;
           currentInsulin = activeInsulinLeft > 0 ? activeInsulinLeft : 0;
           }
           }
           
           retVal.append(ChartPoint(date: date, insulinOnBoard: insulinOnBoard, currentInsulin: currentInsulin))
           
           futureMinute += minuteResolution;
           }*/
          
          
          DispatchQueue.main.async {
            callback(nil, retVal);
          }
        }
      }
    }
    
    self.healthStore.execute(query);
    
  }
}


