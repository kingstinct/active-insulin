//
//  Double+Format.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation

extension Double {
  func format(_ f: String) -> String {
    return String(format: "%\(f)f", self)
  }
}
