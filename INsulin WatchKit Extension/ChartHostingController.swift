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

extension UNNotificationAttachment {
  
  static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
    let fileManager = FileManager.default
    let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
    do {
      try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
      let imageFileIdentifier = identifier+".png"
      let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
      let imageData = UIImage.pngData(image)
      try imageData()?.write(to: fileURL)
      let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
      return imageAttachment
    } catch {
      print("error " + error.localizedDescription)
    }
    return nil
  }
}


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
      Calculations.healthStore.stop(query)
    }
  }
  
  override func didAppear() {
    Calculations.healthStore.getRequestStatusForAuthorization(toShare: [insulinQuantityType], read: [insulinObjectType]) { (status, error) in
      if(status == .unnecessary){
        self.isAuthorized = true;
      } else {
        self.isAuthorized = false;
      }
      self.setNeedsBodyUpdate()
    }
    
    let query = HKObserverQuery.init(sampleType: insulinQuantityType, predicate: nil) { (query, handler, error) in
      self.queryAndUpdateActiveInsulin(handler: handler)
    }
    Calculations.healthStore.execute(query)
    updateQuery = query
  }
  
  func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
    Calculations.fetchActiveInsulin { (error, value) in
      if let iob = value {
        self.activeInsulin = iob
      }
    }
    
    promise = Calculations.fetchActiveInsulinChart(from: Date().advanced(by: TimeInterval(-60 * 60)), to: Date().advanced(by: TimeInterval(5 * 60 * 60))).sink(receiveCompletion: { (errors) in
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

