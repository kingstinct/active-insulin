//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine


struct AuthView: View {
  // 'var onInsulinUpdate: ((_: Double) -> Void)?
  @ObservedObject var appState: AppState = AppState.current;
  @State var mode = false;
  
  @ViewBuilder
  var body: some View {
    ScrollView(){
      Text("We need permissions")
      Button(action: {
        
      }) {
        Text("Allow")
      }
    }.navigationBarTitle(LocalizedStringKey(stringLiteral: "settings"))
  }
}



