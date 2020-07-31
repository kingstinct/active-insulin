//
//  Stepper.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-28.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct Stepper: View {
  @Binding var value: Double
  var stepSize: Double = 0.5
  var format: String = "0.1";
  @State private var rotation: Double = 0.0
  @State private var lastRotation: Double = 0.0
  
  func updateInsulin(changeBy: Double){
    var setTo = value + changeBy;
    if(setTo < stepSize){
      setTo = stepSize
    }
    
    self.value = setTo
  }
  
  func onRotation(rotation: Double) -> Void {
    let diff = rotation - self.lastRotation
    
    if(diff >= 1){
      self.lastRotation = round(rotation)
      self.updateInsulin(changeBy: stepSize)
    }
    else if(diff <= -1){
      self.lastRotation = round(rotation)
      self.updateInsulin(changeBy: -stepSize)
    }
  }
  
  func onButtonPlus() -> Void {
    self.updateInsulin(changeBy: stepSize)
    
    WKInterfaceDevice.current().play(.directionUp)
  }
  
  func onButtonMinus() -> Void {
    self.updateInsulin(changeBy: -stepSize)
    
    WKInterfaceDevice.current().play(.directionDown)
  }
  var body: some View {
    return HStack {
      Button(action: onButtonMinus) {
        Text("-").bold()
      }.disabled(!(self.value > stepSize)).accentColor(self.value > stepSize
        ? Color(UIColor.magenta)
        : Color(UIColor.magenta.withAlphaComponent(0.8)))
      
      Text(value.format(format))
        .foregroundColor(Color(UIColor.magenta))
        .frame(minWidth: 0, maxWidth: CGFloat.infinity, alignment: .center)
      
      Button(action: onButtonPlus) {
        Text("+").bold()
      }.accentColor(Color(UIColor.magenta))
    }.focusable(true)
      .digitalCrownRotation(
        $rotation,
        from: -100000,
        through: 100000,
        by: 1,
        sensitivity: .medium,
        isContinuous: true,
        isHapticFeedbackEnabled: true
    ).onAppear() {
      
    }.onReceive(Just(rotation), perform: onRotation)
  }
}
