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



class ChartHostingController: WKHostingController<ChartView> {
    let insulinQuantityType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!;
    var activeInsulin: Double = 0
    let healthStore = HKHealthStore()
    var promise: AnyCancellable?
    var anotherPromise: AnyCancellable?
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
                
                let query = HKObserverQuery.init(sampleType: self.insulinQuantityType, predicate: nil) { (query, handler, error) in
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
        
        anotherPromise = Calculations.fetchActiveInsulin(healthStore: self.healthStore).sink(receiveCompletion: { (error) in
            
        }, receiveValue: { (value) in
            self.activeInsulin = value
        })
        
        promise = Calculations.fetchActiveInsulinChart(healthStore: self.healthStore, from: Date().advanced(by: TimeInterval(-60 * 60)), to: Date().advanced(by: TimeInterval(5 * 60 * 60))).sink(receiveCompletion: { (errors) in
            // handle error
            // handler();
        }) { (vals) in
            DispatchQueue.main.async {
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
                    
                    self.image = newImage
                    
                    self.setNeedsBodyUpdate()
                }
                
                
                // chart.smooth = true;
                /*let newVals = vals.map({ (_: Date, value: Double) -> NSNumber in
                
                    return NSNumber(value: value);
                })*/
                
                
                handler();
            }
        }
    }
    
    override var body: ChartView {
        let optionalData = OptionalData();
        optionalData.chartImage = self.image;
        return ChartView(activeInsulin: activeInsulin, optionalData: optionalData)
    }
}

struct ChartHostingController_Previews: PreviewProvider {
    static var previews: some View {
        let optionalData = OptionalData();
        return ChartView(activeInsulin: 5, optionalData: optionalData)
    }
}
