//
//  AppState.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
import Combine;

let INSULIN_DURATION_IN_MINUTES_KEY = "INSULIN_DURATION_IN_MINUTES";
let INSULIN_STEP_KEY = "INSULIN_STEP";
let INSULIN_INITIAL_UNITS_KEY = "INSULIN_INITIAL_UNITS";
let INSULIN_PEAK_TIME_IN_MINUTES_KEY = "INSULIN_PEAK_TIME_IN_MINUTES";

enum AuthStatus {
  case uninitialized;
  case authorized;
  case unauthorized;
  
}

class AppState: ObservableObject {
  @Published var isHealthKitAuthorized: AuthStatus = .uninitialized
  
  @Published var totalDurationInMinutes: Double;
  @Published var peakTimeInMinutes: Double;
  @Published var initialInsulinUnits: Double;
  @Published var insulinStepSize: Double;
  
  var updaters = Array<AnyCancellable>()
  
  init() {
    totalDurationInMinutes = UserDefaults.standard.double(forKey: INSULIN_DURATION_IN_MINUTES_KEY) != 0 ? UserDefaults.standard.double(forKey: INSULIN_DURATION_IN_MINUTES_KEY) : 360;
    peakTimeInMinutes = UserDefaults.standard.double(forKey: INSULIN_PEAK_TIME_IN_MINUTES_KEY) != 0 ? UserDefaults.standard.double(forKey: INSULIN_PEAK_TIME_IN_MINUTES_KEY) : 75;
    initialInsulinUnits = UserDefaults.standard.double(forKey: INSULIN_INITIAL_UNITS_KEY) != 0 ? UserDefaults.standard.double(forKey: INSULIN_INITIAL_UNITS_KEY) : 4;
    insulinStepSize = UserDefaults.standard.double(forKey: INSULIN_STEP_KEY) != 0 ? UserDefaults.standard.double(forKey: INSULIN_STEP_KEY) : 0.5;

    updaters.append(contentsOf: [
      $peakTimeInMinutes.sink { (peakTimeInMinutes) in
        UserDefaults.standard.set(peakTimeInMinutes, forKey: INSULIN_PEAK_TIME_IN_MINUTES_KEY)
      },
      
      $totalDurationInMinutes.sink { (val) in
        UserDefaults.standard.set(val, forKey: INSULIN_DURATION_IN_MINUTES_KEY)
      },
      
      $insulinStepSize.sink { (val) in
        UserDefaults.standard.set(val, forKey: INSULIN_STEP_KEY)
      },
      
      $initialInsulinUnits.sink { (val) in
      UserDefaults.standard.set(val, forKey: INSULIN_INITIAL_UNITS_KEY)
      }
    ])
  }
  
  static var _current: AppState?;
  
  static func current() -> AppState {
    _current = _current ??  AppState()
    return _current!;
  }
}
