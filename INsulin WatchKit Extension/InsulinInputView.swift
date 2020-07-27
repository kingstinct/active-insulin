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
  @State private var insulin: Double = AppState.current().initialInsulinUnits;
  @State private var insulinStr: String = AppState.current().initialInsulinUnits.format(f: "0.1");
  @State private var rotation: Double = 0.0
  @State private var lastRotation: Double = 0.0
  var saveAction: ((_: Double) -> Void)?
  @ObservedObject var appState: AppState
  
  func updateInsulin(changeBy: Double){
    var setTo = insulin + changeBy;
    if(setTo < appState.insulinStepSize){
      setTo = appState.insulinStepSize
    }
    insulin = setTo
    insulinStr = setTo.format(f: "0.1")
  }
  
  @ViewBuilder
  var body: some View {
    if(appState.isHealthKitAuthorized == .authorized){
      
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
            
          }.onReceive(Just(rotation)) { output in
            let diff = output - self.lastRotation
            
            if(diff >= 1){
              self.lastRotation = round(output)
              self.updateInsulin(changeBy: self.appState.insulinStepSize)
            }
            else if(diff <= -1){
              print(output);
              self.lastRotation = round(output)
              self.updateInsulin(changeBy: -self.appState.insulinStepSize)
            }
          }
          
          HStack {
            
            Button(action: {
              self.updateInsulin(changeBy: -self.appState.insulinStepSize)
              
              WKInterfaceDevice.current().play(.directionDown)
            }) {
              Text("-").bold()
            }.disabled(!(self.insulin > self.appState.insulinStepSize)).accentColor(self.insulin > self.appState.insulinStepSize
              ? Color(UIColor.magenta)
              : Color(UIColor.magenta.withAlphaComponent(0.8)))
            
            Text(insulinStr)
              .foregroundColor(Color(UIColor.magenta))
              .frame(minWidth: 0, maxWidth: CGFloat.infinity, alignment: .center)
            
            Button(action: {
              self.updateInsulin(changeBy: self.appState.insulinStepSize)
              
              WKInterfaceDevice.current().play(.directionUp)
            }) {
              Text("+").bold()
            }.accentColor(Color(UIColor.magenta))
          }
          
          Button(action: {
            self.appState.initialInsulinUnits = self.insulin;
            self.saveAction?(self.insulin)
            WKInterfaceDevice.current().play(.success)
          }){
            Text(NSLocalizedString("save", comment: "Save"))
          }
          
          /*.foregroundColor(Color(UIColor.white))
           .background(Color(UIColor.magenta)).cornerRadius(10)*/
        }.navigationBarTitle(LocalizedStringKey(stringLiteral: "add"))
    } else if(appState.isHealthKitAuthorized == .unauthorized){
      Text(NSLocalizedString("please_authorize", comment: "Please authorize"))
    }
    EmptyView();
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    
    return InsulinInputView(saveAction: nil, appState: AppState.current())
  }
}



