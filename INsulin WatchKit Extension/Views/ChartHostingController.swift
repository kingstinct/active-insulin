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
  var activeInsulin: Double = 0;
  var image: UIImage?;
  var updateQuery: HKQuery? = nil;
  var updateActiveEnergyQuery: HKQuery? = nil;
  let chartWidth = Double(WKInterfaceDevice.current().screenBounds.width) - 4;
  let chartHeight: Double = 100;
  let timeFormatter = DateFormatter();
  var insulinLast24Hours: Double? = nil;
  var insulinLast2weeks: StatsResponse? = nil;
  var activeEnergyLast24Hours: StatsResponse? = nil;
  var activeEnergyLast2weeks: StatsResponse? = nil;
  var timer: Timer? = nil;
  
  var injections: Array<Injection>? = nil
  
  var isHealthkitAuthorized: HKAuthorizationRequestStatus?
  
  var isAuthorized = true;
  
  var listenToSelf: AnyCancellable?
  
  override init() {
    super.init()
    self.timeFormatter.dateFormat = "HH:mm";
  }
  
  func openInjectionDetails(injection: Injection){
    self.pushController(withName: "InjectionView", context: [
      "injection": injection
    ])
  }
  
  override func awake(withContext context: Any?) {
    print("awake: ChartHostingController")
    
    listenToSelf = AppState.current.$activePage.sink { (page) in
      if(page == .chart){
        self.becomeCurrentPage()
        // self.crownSequencer.focus()
      } else {
        // self.crownSequencer.resignFocus()
      }
    }
  }
  
  func initQuery(){
    timer = Timer.init(timeInterval: TimeInterval(60), repeats: true, block: { (_) in
      self.queryAndUpdateActiveInsulin {
        
      }
    })
    
    if(self.updateQuery == nil){
      let query = HKObserverQuery.init(sampleType: Health.current.insulinQuantityType, predicate: nil) { (query, handler, error) in
        
        if let error = error {
          self.presentAlert(withTitle: "HK Observer Error", message: error.localizedDescription, preferredStyle: WKAlertControllerStyle.alert, actions: [])
        }
        self.queryAndUpdateActiveInsulin(handler: handler);
      }
      Health.current.healthStore.execute(query)
      self.updateQuery = query;
    }
    
    
    if(self.updateActiveEnergyQuery == nil){
      let activeEnergyQuery = HKObserverQuery.init(sampleType: Health.current.activeEnergyQuantityType, predicate: nil) { (query, handler, error) in
        if let error = error {
          self.presentAlert(withTitle: "HK Observer Error", message: error.localizedDescription, preferredStyle: .alert, actions: []);
        }
        self.queryAndUpdateActiveEnergy(handler: handler);
      }
      
      Health.current.healthStore.execute(activeEnergyQuery)
      
      self.updateActiveEnergyQuery = activeEnergyQuery;
    }
  }
  
  
  func checkForAuth() {
    Health.current.healthStore.getRequestStatusForAuthorization(toShare: [], read: [Health.current.insulinObjectType]) { (status, error) in
      DispatchQueue.main.async {
        self.isHealthkitAuthorized = status;
        
        if(status == .unnecessary){
          
        }
        else if(status == .shouldRequest){
          self.presentAuthAlert { (_, _) in
            self.checkForAuth()
          }
        }
      }
    }
  }
  
  
  override func willActivate() {
    print("willActivate: ChartHostingController")
    
    checkForAuth()
    self.initQuery();
    
    /*if(AppState.current.activePage != .chart) {
     AppState.current.activePage = .chart
     }*/
  }
  
  override func didDeactivate() {
    print("didDeactivate: ChartHostingController")
    /*if let query = updateQuery {
     Health.current.healthStore.stop(query);
     }
     if let energyQuery = updateActiveEnergyQuery {
     Health.current.healthStore.stop(energyQuery);
     }*/
    if let timer = timer {
      timer.invalidate()
    }
  }
  
  override func willDisappear() {
    print("willDisappear: ChartHostingController")
    
    
  }
  
  override func didAppear() {
    checkForAuth()
    /*self.queryAndUpdateActiveInsulin {
     
     }*/
    
    print("didAppear: ChartHostingController")
    NSUserActivity.displayIOBActivityType().becomeCurrent();
    
    if(AppState.current.activePage != .chart) {
      AppState.current.activePage = .chart
    }
    
  }
  
  func queryAndUpdateActiveEnergy (handler: @escaping HKObserverQueryCompletionHandler) {
    Health.current.fetchActiveEnergyStats(start: Date().addHours(addHours: -24)) { (error, last24hours) in
      
      if let error = error {
        self.presentAlert(withTitle: "HK 24 hour energy Error", message: error.localizedDescription, preferredStyle: .alert, actions: []);
      }
      
      Health.current.fetchActiveEnergyStats(start: Date().addHours(addHours: -24 * 15), end: Date().addHours(addHours: -24 * 1)) { (error, last2weeks) in
        
        if let error = error {
          self.presentAlert(withTitle: "HK 2 week energy Error", message: error.localizedDescription, preferredStyle: .alert, actions: []);
        }
        
        DispatchQueue.main.async {
          self.activeEnergyLast2weeks = last2weeks;
          self.activeEnergyLast24Hours = last24hours;
          self.setNeedsBodyUpdate();
          handler();
        }
        
      }
    }
  }
  
  func queryAndUpdateActiveInsulin (handler: @escaping HKObserverQueryCompletionHandler) {
    
    Health.current.fetchInjections(from: Date().addHours(addHours: -360)) { (error, injections) in
      
      if let error = error {
        self.presentAlert(withTitle: "HK injections Error", message: error.localizedDescription, preferredStyle: .alert, actions: []);
      }
      
      if let injections = injections {
        let last24hours = injections.reversed().filter { (injection) -> Bool in
          injection.date >= Date().addHours(addHours: -24)
        }
        self.injections = last24hours;
        
        self.insulinLast24Hours = last24hours.reduce(0, { (acc, injection) -> Double in
          return acc + injection.insulinUnits
        });
        
        let vals = Health.current.buildChartData(injections: last24hours, from: Date().addHours(addHours: -1), to: Date().addHours(addHours: 6), minuteResolution: 2)
        
        let newImage = ChartBuilder.getChartImage(vals: vals, width: self.chartWidth, chartHeight: self.chartHeight);
        
        let last2Weeks = injections.filter { (injection) -> Bool in
          injection.date < Date().addHours(addHours: -24)
        }
        
        let maxLast2Weeks = last2Weeks.max { (inj1, inj2) -> Bool in
          return inj1.insulinUnits > inj2.insulinUnits;
          }?.insulinUnits
        
        let mostRecentQuantity = last2Weeks.last?.insulinUnits;
        
        let mostRecentTime = last2Weeks.last?.date;
        
        let sum = last2Weeks.reduce(0) { (prev, inj) -> Double in
          return prev + inj.insulinUnits
        }
        
        let startDate = last2Weeks.first?.date ?? Date();
        let endDate = last2Weeks.last?.date ?? Date();
        let totalDays = 0.5 + (startDate.distance(to: endDate) / (60 * 60 * 24));
        
        DispatchQueue.main.async {
          self.image = newImage
          self.insulinLast2weeks = StatsResponse.init(
            maximumQuantity: maxLast2Weeks,
            mostRecentQuantity: mostRecentQuantity,
            mostRecentTime: mostRecentTime,
            sumQuantity: sum,
            startDate: startDate,
            endDate: endDate,
            totalDays: totalDays
          );
          self.activeInsulin = Health.current.iobFromValues(injections: last24hours)
          self.setNeedsBodyUpdate();
          handler();
        }
      }
    }
  }
  
  override var body: ChartView {
    let optionalData = OptionalData();
    optionalData.chartImage = self.image;
    return ChartView(
      insulinOnBoard: activeInsulin,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      isHealthKitAuthorized: isHealthkitAuthorized,
      activeEnergyLast2Weeks: activeEnergyLast2weeks?.sumQuantity != nil && activeEnergyLast2weeks?.totalDays != nil && activeEnergyLast2weeks!.totalDays! > 1 ? activeEnergyLast2weeks!.sumQuantity! / activeEnergyLast2weeks!.totalDays! : 0,
      activeEnergyLast24Hours: activeEnergyLast24Hours?.sumQuantity ?? 0,
      insulinUnitsLast2Weeks: insulinLast2weeks?.sumQuantity != nil && insulinLast2weeks?.totalDays != nil && insulinLast2weeks!.totalDays! > 2 ? insulinLast2weeks!.sumQuantity! / insulinLast2weeks!.totalDays! : 0, openInjectionDetails: self.openInjectionDetails,
      insulinUnitsLast24Hours: insulinLast24Hours ?? 0,
      daysOfDataInsulin: insulinLast2weeks?.totalDays ?? 0,
      daysOfDataActiveEnergy: activeEnergyLast2weeks?.totalDays ?? 0,
      timeFormatter: timeFormatter,
      
      injections: self.injections,
      appState: AppState.current,
      optionalData: optionalData
    )
  }
}

