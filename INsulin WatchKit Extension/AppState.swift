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

enum Pages {
  case insulinInput;
  case chart;
  case settings;
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
  @Published(key: "INSULIN_STEP_SIZE") var insulinStepSize = 1.0;
  
  @Published(key: "NOTIFY_ON_INSULIN_PEAK_ENABLED") var notifyOnInsulinPeakEnabled = true;
  @Published(key: "NOTIFY_ON_INSULIN_ZERO_ENABLED") var notifyOnInsulinZeroEnabled = false;
  @Published(key: "NOTIFY_ON_INSULIN_CUSTOM_MINUTES") var notifyOnCustomMinutes: Double = 90;
  @Published(key: "NOTIFY_ON_INSULIN_CUSTOM_ENABLED") var notifyOnCustomEnabled = false;
  
  @Published(key: "NOTIFICATION_SNOOZE_15_ENABLED") var snooze15Enabled = false;
  @Published(key: "NOTIFICATION_SNOOZE_30_ENABLED") var snooze30Enabled = true;
  @Published(key: "NOTIFICATION_SNOOZE_60_ENABLED") var snooze60Enabled = false;
  
  @Published var activePage: Pages = .chart;
  
  @Published(key: "IS_PREMIUM_UNTIL") var isPremiumUntil: Double = 0;
  
  static var current = AppState();
}
