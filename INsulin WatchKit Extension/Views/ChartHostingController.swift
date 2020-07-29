//
//  ChartHostingController.swift
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
  var image: UIImage?
  var updateQuery: HKQuery?;
  let chartWidth = Double(WKInterfaceDevice.current().screenBounds.width) - 4
  let chartHeight: Double = 80;
  var insulinLast24Hours: StatsResponse? = nil
  var insulinLast2weeks: StatsResponse? = nil
  var insulinPrevious2weeks: StatsResponse? = nil
  var activeEnergyLast24Hours: StatsResponse? = nil
  var activeEnergyLast2weeks: StatsResponse? = nil
  var activeEnergyPrevious2weeks: StatsResponse? = nil
  var timer: Timer? = nil;
  
  var isAuthorized = true;
  
  override func willDisappear() {
    if let query = updateQuery {
      Health.current.healthStore.stop(query)
    }
    if let timer = timer {
      timer.invalidate()
    }
  }
  
  override func didAppear() {
    NSUserActivity.displayIOBActivityType().becomeCurrent()
    timer = Timer.init(timeInterval: TimeInterval(60), repeats: true, block: { (_) in
      self.queryAndUpdateActiveInsulin {
        
      }
    })
    
    let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
      self.queryAndUpdateActiveInsulin(handler: handler)
    }
    Health.current.healthStore.execute(query);
    updateQuery = query;
  }
  
  func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
    Health.current.fetchInsulinStats(start: Date().addHours(addHours: -24)) { (error, response) in
      self.insulinLast24Hours = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchInsulinStats(start: Date().addHours(addHours: -24 * 14)) { (error, response) in
      self.insulinLast2weeks = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchActiveEnergyStats(start: Date().addHours(addHours: -24 * 14)) { (error, response) in
      self.activeEnergyLast2weeks = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchInsulinStats(start: Date().addHours(addHours: -24 * 28), end: Date().addHours(addHours: -24 * 14)) { (error, response) in
      self.insulinPrevious2weeks = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchActiveEnergyStats(start: Date().addHours(addHours: -24 * 28), end: Date().addHours(addHours: -24 * 14)) { (error, response) in
      self.activeEnergyPrevious2weeks = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchActiveEnergyStats(start: Date().addHours(addHours: -24)) { (error, response) in
      self.activeEnergyLast24Hours = response;
      self.setNeedsBodyUpdate()
    }
    Health.current.fetchIOB { (error, value) in
      if let iob = value {
        self.activeInsulin = iob
        self.setNeedsBodyUpdate()
      }
    }
    
    Health.current.fetchActiveInsulinChart(from: Date().addHours(addHours: -1), to: Date().addHours(addHours: 6)) { (error, vals) in
      DispatchQueue.main.async {
        let newImage = ChartBuilder.getChartImage(vals: vals, width: self.chartWidth, chartHeight: self.chartHeight);
        
        self.image = newImage
        
        self.setNeedsBodyUpdate()
      }
      
      handler();
      
    }
    
  }
  
  override var body: ChartView {
    let optionalData = OptionalData();
    optionalData.chartImage = self.image;
    return ChartView(activeInsulin: activeInsulin,
                     chartWidth: chartWidth,
                     chartHeight: chartHeight,
                     insulinLast2weeks: insulinLast2weeks,
                     insulinLast24hours: insulinLast24Hours,
                     insulinPrevious2weeks: insulinPrevious2weeks,
                     activeEnergyLast2weeks: activeEnergyLast2weeks,
                     activeEnergyPrevious2weeks: activeEnergyPrevious2weeks,
                     activeEnergyLast24hours: activeEnergyLast24Hours,
                     appState: AppState.current,
                     optionalData: optionalData)
  }
}

struct ChartHostingController_Previews: PreviewProvider {
  static var previews: some View {
    let optionalData = OptionalData();
    let width = Double(WKInterfaceDevice.current().screenBounds.width);
    let height = 100.0;
    return ChartView(activeInsulin: 5, chartWidth: width, chartHeight: height, appState: AppState.current, optionalData: optionalData)
  }
}

