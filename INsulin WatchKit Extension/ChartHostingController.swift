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
  var promise: AnyCancellable?
  var anotherPromise: AnyCancellable?
  var image: UIImage?
  var updateQuery: HKQuery?;
  
  var isAuthorized = true;
  
  override func willDisappear() {
    if let query = updateQuery {
      Health.current.healthStore.stop(query)
    }
  }
  
  override func didAppear() {
    NSUserActivity.displayIOBActivityType().becomeCurrent()
    
    let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
      self.queryAndUpdateActiveInsulin(handler: handler)
    }
    Health.current.healthStore.execute(query)
    updateQuery = query
  }
  
  func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
    Health.current.fetchIOB { (error, value) in
      if let iob = value {
        self.activeInsulin = iob
      }
    }
    
    Health.current.fetchActiveInsulinChart(from: Date().addHours(addHours: -1), to: Date().addHours(addHours: 5)) { (error, vals) in
      DispatchQueue.main.async {
      let newImage = ChartBuilder.getChartImage(vals: vals);
      
      self.image = newImage
      
      self.setNeedsBodyUpdate()
      }
      
      handler();
      
    }
    
  }
  
  override var body: ChartView {
    let optionalData = OptionalData();
    optionalData.chartImage = self.image;
    return ChartView(activeInsulin: activeInsulin, appState: AppState.current, optionalData: optionalData)
  }
}

struct ChartHostingController_Previews: PreviewProvider {
  static var previews: some View {
    let optionalData = OptionalData();
    return ChartView(activeInsulin: 5, appState: AppState.current, optionalData: optionalData)
  }
}

