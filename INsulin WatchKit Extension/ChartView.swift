//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine

class OptionalData: ObservableObject {
  @Published var chartImage: UIImage?
}

struct ChartView: View {
  var activeInsulin: Double
  @ObservedObject var appState: AppState
  @ObservedObject var optionalData: OptionalData
  @ViewBuilder
  var body: some View {
    if(appState.isHealthKitAuthorized == .authorized){
      ScrollView(){
        VStack(alignment: .leading, spacing: 0){
          Text(NSLocalizedString("insulin_on_board", comment: "Insulin on board")).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
          if(self.optionalData.chartImage != nil){
            Image(uiImage: self.optionalData.chartImage!)
          } else {
            Text("Loading chart..")
          }
          HStack(alignment: .top, spacing: 0) {
            Text("-1h")
            Text("\(activeInsulin.format(f: "0.1"))").multilineTextAlignment(.center).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).foregroundColor(Color(UIColor.magenta))
            Text("+5h").multilineTextAlignment(.trailing).frame(alignment: .trailing)
          }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
          
        }
      }.navigationBarTitle(LocalizedStringKey("active"))
    } else if(appState.isHealthKitAuthorized == .unauthorized){
      Text(NSLocalizedString("please_authorize", comment: "Please authorize"))
    }
    EmptyView()
  }
}

struct ChartView_Previews: PreviewProvider {
  static var previews: some View {
    let optionalData = OptionalData()
    return ChartView(activeInsulin: 5, appState: AppState.current(), optionalData: optionalData)
  }
}


