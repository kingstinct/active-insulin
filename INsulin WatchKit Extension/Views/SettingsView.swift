//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine


struct SettingsView: View {
  // 'var onInsulinUpdate: ((_: Double) -> Void)?
  @ObservedObject var appState: AppState = AppState.current;
  @State var mode = false;
  
  @ViewBuilder
  var body: some View {
    ScrollView(){
      VStack(alignment: .center){
        NavigationLink(destinationName: "NotificationsView") {
          Text("notifications")
        }
        NavigationLink(destinationName: "SettingsStepSizeView") {
          Text("insulin")
        }
      }
    }.navigationBarTitle(LocalizedStringKey(stringLiteral: "settings"))
  }
}



