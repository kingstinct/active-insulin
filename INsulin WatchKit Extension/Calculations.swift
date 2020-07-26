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

class Calculations {
    static func timeConstantOfExpDecay(peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double {
        let part1 = 1 - peakTimeInMinutes / totalDurationInMinutes;
        let part2 = 1 - 2 * peakTimeInMinutes / totalDurationInMinutes;
        return peakTimeInMinutes * part1 / part2;
    }
    
    static func riseTimeFactor(timeConstantOfExpDecay: Double, peakTimeInMinutes: Double) -> Double {
        return 2 * timeConstantOfExpDecay / peakTimeInMinutes;
    }
    
    static func auxiliaryScaleFactor(riseTimeFactor: Double, totalDurationInMinutes: Double, timeConstantOfExpDecay: Double) -> Double {
        return 1 / (1-riseTimeFactor + (1 + riseTimeFactor) * exp(-totalDurationInMinutes/timeConstantOfExpDecay))
    }
    
    static func insulinActivityCurve(t: Double, peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double {
        let tau = timeConstantOfExpDecay(peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
        let a = riseTimeFactor(timeConstantOfExpDecay: tau, peakTimeInMinutes: peakTimeInMinutes);
        let S = auxiliaryScaleFactor(riseTimeFactor: a, totalDurationInMinutes: totalDurationInMinutes, timeConstantOfExpDecay: tau)
        let part1 = S / pow(tau, 2);
        let part2 = 1 - t / totalDurationInMinutes;
        return part1 * t * part2 * exp(-t/tau)
    }
    
    // as in https://github.com/LoopKit/Loop/issues/388#issuecomment-317938473
    static func iobCurve(t: Double, peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double{
        let tau = timeConstantOfExpDecay(peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
        let a = riseTimeFactor(timeConstantOfExpDecay: tau, peakTimeInMinutes: peakTimeInMinutes);
        let S = auxiliaryScaleFactor(riseTimeFactor: a, totalDurationInMinutes: totalDurationInMinutes, timeConstantOfExpDecay: tau)
        let part1: Double = 1-a;
        let part2: Double = pow(t,2)/(tau * totalDurationInMinutes * (1-a)) - t/tau - 1;
        let part3 = part2 * exp(-t/tau) + 1.0;
        return Double(1) - (S * part1 * part3);
    }
    
    static func fetchActiveInsulin(healthStore: HKHealthStore, forTime: Date? = nil) -> Future<Double, Error>{
        return Future { promise in
            let totalDurationInMinutes: Double = 360;
            let peakTimeInMinutes: Double = 75;
            let dateTime = forTime ?? Date();
            // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
            let from = dateTime.advanced(by: TimeInterval(exactly: -totalDurationInMinutes * 60)!);
            
            let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: from, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
                if let e = error {
                    promise(.failure(e));
                } else {
                    if let samples = _samples as? [HKQuantitySample] {
                        var totalActiveInsulinLeft: Double = 0;
                        for sample in samples {
                            let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
                            let minutesAgo = -sample.startDate.timeIntervalSince(dateTime) / 60;
                            if(minutesAgo <= totalDurationInMinutes){
                                let iobFactor = self.iobCurve(t: minutesAgo, peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
                                let activeInsulinLeft = quantity * iobFactor;
                                totalActiveInsulinLeft += activeInsulinLeft;
                            }
                        }
                        
                        DispatchQueue.main.async {
                            promise(.success(totalActiveInsulinLeft));
                        }
                    }
                }
            }
            
            healthStore.execute(query);
        }
        
    }
    
    
    
    static func fetchActiveInsulinTimeline(healthStore: HKHealthStore, from: Date, to: Date, minuteResolution: Double = 2) -> Future<[(Date, Double)], Error>{
        return Future { promise in
            let totalDurationInMinutes: Double = 360;
            let peakTimeInMinutes: Double = 75;
            // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
            let queryFrom = from.advanced(by: TimeInterval(exactly: -totalDurationInMinutes * 60)!);
            
            let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
                if let e = error {
                    promise(.failure(e));
                } else {
                    if let samples = _samples as? [HKQuantitySample] {
                        var futureMinute: Double = 0;
                        var retVal = Array<(Date, Double)>();
                        while(futureMinute <= to.timeIntervalSince(from) / 60){
                            let date = from.advanced(by: TimeInterval(futureMinute * 60))
                            var totalActiveInsulinLeft: Double = 0;
                            for sample in samples {
                                let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
                                let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
                                // if(minutesAgo <= totalDurationInMinutes && minutesAgo >= 0){
                                    let iobFactor = self.iobCurve(t: minutesAgo, peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
                                    let activeInsulinLeft = quantity * iobFactor;
                                    totalActiveInsulinLeft += activeInsulinLeft;
                                // }
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
            
            healthStore.execute(query);
        }
        
    }
    
    
    static func fetchActiveInsulinChart(healthStore: HKHealthStore, from: Date, to: Date, minuteResolution: Double = 2) -> Future<[(Date, Double)], Error>{
        return Future { promise in
            let totalDurationInMinutes: Double = 360;
            let peakTimeInMinutes: Double = 75;
            // let from = Date.init(timeIntervalSinceNow: TimeInterval(exactly: -totalDurationInMinutes * 60)!)
            let queryFrom = from.advanced(by: TimeInterval(exactly: -totalDurationInMinutes * 60)!);
            
            let query = HKSampleQuery.init(sampleType: insulinQuantityType, predicate: HKQuery.predicateForSamples(withStart: queryFrom, end: nil, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (q, _samples, error) in
                if let e = error {
                    promise(.failure(e));
                } else {
                    if let samples = _samples as? [HKQuantitySample] {
                        var futureMinute: Double = 0;
                        var retVal = Array<(Date, Double)>();
                        while(futureMinute <= to.timeIntervalSince(from) / 60){
                            let date = from.advanced(by: TimeInterval(futureMinute * 60))
                            var totalActiveInsulinLeft: Double = 0;
                            for sample in samples {
                                let quantity = sample.quantity.doubleValue(for: HKUnit.internationalUnit());
                                let minutesAgo = -sample.startDate.timeIntervalSince(date) / 60;
                                if(minutesAgo <= totalDurationInMinutes && minutesAgo >= 0){
                                    let activityRightNow = -self.insulinActivityCurve(t: minutesAgo, peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
                                    // print(activityRightNow)
                                    let activeInsulinLeft = quantity * activityRightNow;
                                    totalActiveInsulinLeft += activeInsulinLeft;
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
            
            healthStore.execute(query);
        }
        
    }
    
    
    
    
    /*static func getChartImage(healthStore: HKHealthStore){
        let from = Date().advanced(by: TimeInterval(-60 * 60));
        let to = Date().advanced(by: TimeInterval(5 * 60 * 60));
        
        return self
            .fetchActiveInsulinChart(healthStore: healthStore, from: from, to: to)
            .combineLatest(_: Publisher<UIImage>) { (vals, output: ) -> UIImage in
                if let max = vals.max { (arg0, arg1) -> Bool in
                    return arg0.1 < arg1.1;
                }?.1 {
                    let maxNumber = NSNumber(value: max * 1.5);
                    
                    let futureVals = vals.filter({ (date, value) -> Bool in
                        return date.timeIntervalSinceNow >= 0
                    }).map({ $0.1 });
                    
                    let previousVals = vals.filter({ (date, value) -> Bool in
                        return date.timeIntervalSinceNow < 0
                    }).map({ $0.1 });
                    
                    let previousChart = YOLineChartImage();
                    previousChart.values = previousVals as [NSNumber];
                    previousChart.fillColor = UIColor.magenta.withAlphaComponent(0.3)
                    previousChart.maxValue = maxNumber;
                    // chart.smooth = true
                    previousChart.strokeColor = UIColor.magenta.withAlphaComponent(0.5)
                    previousChart.strokeWidth = 3.0
                    
                    
                    let futureChart = YOLineChartImage();
                    futureChart.values = futureVals as [NSNumber];
                    futureChart.maxValue = maxNumber;
                    futureChart.fillColor = UIColor.magenta.withAlphaComponent(0.6)
                    // chart.smooth = true
                    futureChart.strokeColor = UIColor.magenta
                    futureChart.strokeWidth = 3.0
                    
                    
                    let width = Int(WKInterfaceDevice.current().screenBounds.width);
                    let previousWidth = width * previousVals.count / vals.count;
                    let futureWidth = width * futureVals.count / vals.count;
                    
                    let chartHeight = 100
                    let screenScale = WKInterfaceDevice.current().screenScale
                    
                    let imagePrevious = previousChart.draw(CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight), scale: screenScale)
                    
                    let imageFuture = futureChart.draw(CGRect(x: 0, y: 0, width: futureWidth, height: chartHeight), scale: screenScale)
                    
                    
                    
                    let size = CGSize(width: width, height: chartHeight)
                    UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
                    
                    let context = UIGraphicsGetCurrentContext();
                    
                    let hourDividers = 5;
                    let widthPerDivider = width / (hourDividers + 1)
                    
                    func drawLine(at: Int, lineWidth: CGFloat = 0.5) -> Void {
                        context?.setLineWidth(lineWidth)
                        context?.setStrokeColor(UIColor.darkGray.cgColor);
                        context?.move(to: CGPoint(x: at, y: 0))
                        context?.addLine(to: CGPoint(x: at, y: chartHeight))
                        context?.strokePath()
                    }
                    
                    for i in 0..<hourDividers { /* do something */
                        let x = (i + 1) * widthPerDivider;
                        drawLine(at: x, lineWidth: i == 0 ? 1 : 0.5)
                    }
                    
                    drawLine(at: width - 1)
                    drawLine(at: 1)
                    
                    
                    
                    imagePrevious.draw(in: CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight))
                    imageFuture.draw(in: CGRect(x: previousWidth, y: 0, width: futureWidth, height: chartHeight))

                    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                    
                    return newImage;
            }
        }
        
    }*/
}
