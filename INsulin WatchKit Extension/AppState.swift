//
//  AppState.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
import Combine;

enum AuthStatus {
  case uninitialized;
  case authorized;
  case unauthorized;
}

private var cancellables = [String:AnyCancellable]()

extension Published {
  init(wrappedValue defaultValue: Value, key: String) {
    let value = UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
    self.init(initialValue: value)
    cancellables[key] = projectedValue.sink { val in
      UserDefaults.standard.set(val, forKey: key)
    }
  }
}

class AppState: ObservableObject {
  @Published(key: "INSULIN_DURATION_IN_MINUTES") var insulinDurationInMinutes: Double = 360;
  @Published(key: "INSULIN_PEAK_TIME_IN_MINUTES") var insulinPeakTimeInMinutes: Double = 75;
  @Published(key: "INSULIN_INITIAL_UNITS") var insulinInputInitialUnits = 4.0;
  @Published(key: "INSULIN_STEP_SIZE") var insulinStepSize = 0.5;
  
  @Published(key: "NOTIFY_ON_INSULIN_PEAK_ENABLED") var notifyOnInsulinPeakEnabled = true;
  @Published(key: "NOTIFY_ON_INSULIN_ZERO_ENABLED") var notifyOnInsulinZeroEnabled = false;
  @Published(key: "NOTIFY_ON_INSULIN_CUSTOM_MINUTES") var notifyOnCustomMinutes: Double = 90;
  @Published(key: "NOTIFY_ON_INSULIN_CUSTOM_ENABLED") var notifyOnCustomEnabled = false;
  
  @Published(key: "NOTIFICATION_SNOOZE_15_ENABLED") var snooze15Enabled = false;
  @Published(key: "NOTIFICATION_SNOOZE_30_ENABLED") var snooze30Enabled = true;
  @Published(key: "NOTIFICATION_SNOOZE_60_ENABLED") var snooze60Enabled = false;
  
  var updaters = Array<AnyCancellable>()
  
  static func read(forKey: String, withDefault: Int) -> Int {
    if(UserDefaults.standard.data(forKey: forKey) != nil){
      return UserDefaults.standard.integer(forKey: forKey)
    }
    return withDefault;
  }
  
  /*static func read(forKey: String, withDefault: Double) -> Double {
    if(UserDefaults.standard.data(forKey: forKey) != nil){
      return UserDefaults.standard.double(forKey: forKey)
    }
    return withDefault;
  }
  
  static func read(forKey: String, withDefault: Bool) -> Bool{
    if(UserDefaults.standard.data(forKey: forKey) != nil){
      return UserDefaults.standard.bool(forKey: forKey)
    }
    return withDefault;
  }
  
  static func persist(forKey: String, listenTo: Published<Double>.Publisher) -> AnyCancellable {
    return listenTo.sink { (val) in
      UserDefaults.standard.set(val, forKey: forKey)
    }
  }
  
  static func persist(forKey: String, listenTo: Published<Bool>.Publisher) -> AnyCancellable {
    return listenTo.sink { (val) in
      UserDefaults.standard.set(val, forKey: forKey)
    }
  }
  
  static func persist(forKey: String, listenTo: Published<Int>.Publisher) -> AnyCancellable {
    return listenTo.sink { (val) in
      UserDefaults.standard.set(val, forKey: forKey)
    }
  }*/
  
  /*private init() {
    insulinDurationInMinutes = AppState.read(forKey: "INSULIN_DURATION_IN_MINUTES", withDefault: 360);
    insulinPeakTimeInMinutes = AppState.read(forKey: "INSULIN_PEAK_TIME_IN_MINUTES", withDefault: 75)
    insulinInputInitialUnits = AppState.read(forKey: "INSULIN_INITIAL_UNITS", withDefault: 4);
    insulinStepSize = AppState.read(forKey: "INSULIN_STEP_SIZE", withDefault: 0.5);
    
    notifyOnCustomEnabled = AppState.read(forKey: "NOTIFY_ON_CUSTOM_ENABLED", withDefault: false);
    notifyOnCustomMinutes = AppState.read(forKey: "NOTIFY_ON_CUSTOM_MINUTES", withDefault: 90);
    /// notifyOnInsulinPeakEnabled = AppState.read(forKey: "NOTIFY_ON_INSULIN_PEAK_ENABLED", withDefault: false);
    
    snooze15Enabled = AppState.read(forKey: "NOTIFY_SNOOZE_15", withDefault: false);
    snooze30Enabled = AppState.read(forKey: "NOTIFY_SNOOZE_30", withDefault: true);
    snooze60Enabled = AppState.read(forKey: "NOTIFY_SNOOZE_60", withDefault: false);
    

    updaters.append(contentsOf: [
      AppState.persist(forKey: "INSULIN_PEAK_TIME_IN_MINUTES", listenTo: $insulinPeakTimeInMinutes),
      AppState.persist(forKey: "INSULIN_DURATION_IN_MINUTES", listenTo: $insulinDurationInMinutes),
      AppState.persist(forKey: "INSULIN_STEP_SIZE", listenTo: $insulinStepSize),
      AppState.persist(forKey: "INSULIN_INITIAL_UNITS", listenTo: $insulinInputInitialUnits),
      
      AppState.persist(forKey: "NOTIFY_ON_CUSTOM_ENABLED", listenTo: $notifyOnCustomEnabled),
      AppState.persist(forKey: "NOTIFY_ON_CUSTOM_MINUTES", listenTo: $notifyOnCustomMinutes),
      /// AppState.persist(forKey: "NOTIFY_ON_INSULIN_PEAK_ENABLED", listenTo: $notifyOnInsulinPeakEnabled),
      
      AppState.persist(forKey: "NOTIFY_SNOOZE_15", listenTo: $snooze15Enabled),
      AppState.persist(forKey: "NOTIFY_SNOOZE_30", listenTo: $snooze30Enabled),
      AppState.persist(forKey: "NOTIFY_SNOOZE_60", listenTo: $snooze60Enabled),
    ])
  }*/
  
  static var current = AppState();
  
  /*static func current() -> AppState {
    _current = _current ?? AppState()
    
    dispatchonce
    
    return _current!;
  }*/
}
