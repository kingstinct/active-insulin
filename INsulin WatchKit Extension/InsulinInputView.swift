//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine

struct InsulinInputView: View {
  @State private var insulin: Double = AppState.current.initialInsulinUnits;
  @State private var rotation: Double = 0.0
  @State private var lastRotation: Double = 0.0
  var saveAction: ((_: Double) -> Void)?
  // 'var onInsulinUpdate: ((_: Double) -> Void)?
  @ObservedObject var appState: AppState = AppState.current;
  
  func updateInsulin(changeBy: Double){
    AppState.current.objectWillChange.send()
    var setTo = insulin + changeBy;
    if(setTo < appState.insulinStepSize){
      setTo = appState.insulinStepSize
    }
    
    self.insulin = setTo
  }
  
  func onRotation(rotation: Double) -> Void {
    let diff = rotation - self.lastRotation
    
    if(diff >= 1){
      self.lastRotation = round(rotation)
      self.updateInsulin(changeBy: self.appState.insulinStepSize)
    }
    else if(diff <= -1){
      self.lastRotation = round(rotation)
      self.updateInsulin(changeBy: -self.appState.insulinStepSize)
    }
  }
  
  func onButtonPlus() -> Void {
    self.updateInsulin(changeBy: self.appState.insulinStepSize)
    
    WKInterfaceDevice.current().play(.directionUp)
  }
  
  func onButtonMinus() -> Void {
    self.updateInsulin(changeBy: -self.appState.insulinStepSize)
    
    WKInterfaceDevice.current().play(.directionDown)
  }
  
  func onSave() -> Void {
    self.appState.initialInsulinUnits = self.insulin;
    self.saveAction?(self.insulin)
    WKInterfaceDevice.current().play(.success)
  }
  
  @ViewBuilder
  var body: some View {
    if(appState.isHealthKitAuthorized == .unauthorized){
      Text(NSLocalizedString("please_authorize", comment: "Please authorize"))
    }
    VStack(alignment: .center){
      
      Text(NSLocalizedString("units_of_insulin", comment: "Units of insulin")).focusable(true)
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
      
      HStack {
        
        Button(action: onButtonMinus) {
          Text("-").bold()
        }.disabled(!(self.insulin > self.appState.insulinStepSize)).accentColor(self.insulin > self.appState.insulinStepSize
          ? Color(UIColor.magenta)
          : Color(UIColor.magenta.withAlphaComponent(0.8)))
        
        Text(insulin.format(f: "0.1"))
          .foregroundColor(Color(UIColor.magenta))
          .frame(minWidth: 0, maxWidth: CGFloat.infinity, alignment: .center)
        
        Button(action: onButtonPlus) {
          Text("+").bold()
        }.accentColor(Color(UIColor.magenta))
      }
      
      Button(action: onSave){
        Text(NSLocalizedString("save", comment: "Save"))
      }
      
      /*.foregroundColor(Color(UIColor.white))
       .background(Color(UIColor.magenta)).cornerRadius(10)*/
    }.navigationBarTitle(LocalizedStringKey(stringLiteral: "add"))
  }
}




