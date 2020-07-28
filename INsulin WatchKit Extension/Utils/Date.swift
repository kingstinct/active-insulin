//
//  Date.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-28.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation

extension Date {
  func addHours(addHours: Double) -> Date {
    return self.addingTimeInterval(TimeInterval(addHours * 60 * 60))
  }
  
  func addMinutes(addMinutes: Double) -> Date {
    return self.addingTimeInterval(TimeInterval(addMinutes * 60))
  }
}
