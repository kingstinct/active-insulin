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
  var saveAction: ((_: Double) -> Void)?
  // @State private var insulin: Double = AppState.current.insulinInputInitialUnits
  // 'var onInsulinUpdate: ((_: Double) -> Void)?
  @ObservedObject var appState: AppState = AppState.current;
  
  func onSave() -> Void {
    // self.appState.insulinInputInitialUnits = appState.insulinInputInitialUnits;
    self.saveAction?(appState.insulinInputInitialUnits)
    WKInterfaceDevice.current().play(.success)
  }
  
  @ViewBuilder
  var body: some View {
    if(appState.isHealthKitAuthorized == .unauthorized){
      Text(NSLocalizedString("please_authorize", comment: "Please authorize"))
    }
    VStack(alignment: .center){
      
      Text(NSLocalizedString("units_of_insulin", comment: "Units of insulin"))
      
      Stepper(value: $appState.insulinInputInitialUnits, stepSize: appState.insulinStepSize, format: appState.insulinStepSize == 0.5 ? "0.1" : "1.0")
      
      Button(action: onSave){
        Text(NSLocalizedString("save", comment: "Save"))
      }
      
    }.navigationBarTitle(LocalizedStringKey(stringLiteral: "add"))
  }
}



