//
//  Calculations.swift
//  INsulin WatchKit Extension
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

// as in https://github.com/LoopKit/Loop/issues/388#issuecomment-317938473
class Calculations {
  static func timeConstantOfExpDecay(peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double {
    let part1 = 1 - peakTimeInMinutes / totalDurationInMinutes;
    let part2 = 1 - 2 * peakTimeInMinutes / totalDurationInMinutes;
    return peakTimeInMinutes * part1 / part2;
  }
  
  static func riseTimeFactor(timeConstantOfExpDecay: Double, peakTimeInMinutes: Double) -> Double {
    return 2 * timeConstantOfExpDecay / peakTimeInMinutes;
  }
  
  static func auxiliaryScaleFactor(riseTimeFactor: Double, totalDurationInMinutes: Double, timeConstantOfExpDecay: Double) -> Double {
    return 1 / (1-riseTimeFactor + (1 + riseTimeFactor) * exp(-totalDurationInMinutes/timeConstantOfExpDecay))
  }
  
  static func insulinActivityCurve(t: Double, peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double {
    let tau = timeConstantOfExpDecay(peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
    let a = riseTimeFactor(timeConstantOfExpDecay: tau, peakTimeInMinutes: peakTimeInMinutes);
    let S = auxiliaryScaleFactor(riseTimeFactor: a, totalDurationInMinutes: totalDurationInMinutes, timeConstantOfExpDecay: tau)
    let part1 = S / pow(tau, 2);
    let part2 = 1 - t / totalDurationInMinutes;
    return part1 * t * part2 * exp(-t/tau)
  }
  
  static func iobCurve(t: Double, peakTimeInMinutes: Double, totalDurationInMinutes: Double) -> Double{
    let tau = timeConstantOfExpDecay(peakTimeInMinutes: peakTimeInMinutes, totalDurationInMinutes: totalDurationInMinutes);
    let a = riseTimeFactor(timeConstantOfExpDecay: tau, peakTimeInMinutes: peakTimeInMinutes);
    let S = auxiliaryScaleFactor(riseTimeFactor: a, totalDurationInMinutes: totalDurationInMinutes, timeConstantOfExpDecay: tau)
    let part1: Double = 1-a;
    let part2: Double = pow(t,2)/(tau * totalDurationInMinutes * (1-a)) - t/tau - 1;
    let part3 = part2 * exp(-t/tau) + 1.0;
    return Double(1) - (S * part1 * part3);
  }
}

