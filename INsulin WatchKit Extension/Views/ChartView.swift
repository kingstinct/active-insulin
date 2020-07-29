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

let cellWidth = WKInterfaceDevice.current().screenBounds.width / 5.5;

struct TrendArrow: View {
  var value: Double;
  var compareWith: Double;
  
  var body: some View {
    Image(systemName: value > compareWith * 2 ? "arrow.up" : value > compareWith ? "arrow.up.right" : value == compareWith ? "arrow.right" : value * 2 < compareWith ?  "arrow.down" : "arrow.down.right")
  }
}

struct ChartView: View {
  var activeInsulin: Double
  var chartWidth: Double
  var chartHeight: Double
  var insulinLast2weeks: StatsResponse?
  var insulinLast24hours: StatsResponse?
  var insulinPrevious2weeks: StatsResponse?
  var activeEnergyLast2weeks: StatsResponse?
  var activeEnergyPrevious2weeks: StatsResponse?
  var activeEnergyLast24hours: StatsResponse?
  @State var isFocusable = true
  @ObservedObject var appState: AppState
  @ObservedObject var optionalData: OptionalData
  @ViewBuilder
  var body: some View {
    
    if(appState.isHealthKitAuthorized == .unauthorized){
      Text(NSLocalizedString("please_authorize", comment: "Please authorize"))
    } else {
      ScrollView(){
        VStack(alignment: .leading, spacing: 0){
          if(insulinLast24hours?.sumQuantity == 0){
            NavigationLink(destinationName: "InsulinInputView") {
              Text("Add some insulin")
            }.padding()
          } else {
            
          }
          
          Text(NSLocalizedString("insulin_on_board", comment: "Insulin on board")).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
          HStack(alignment: .center) {
            if(self.optionalData.chartImage != nil){
              Image(uiImage: self.optionalData.chartImage!)
            } else {
              
            }
          }.frame(maxWidth: CGFloat(chartWidth), minHeight: CGFloat(chartHeight), maxHeight: CGFloat(chartHeight), alignment: .center).background(Color.AlmosterBlack).cornerRadius(5)
          HStack(alignment: .top, spacing: 0) {
            Text("-1h")
            Text("\(activeInsulin.format(f: "0.1"))").multilineTextAlignment(.center).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).foregroundColor(Color(UIColor.magenta))
            Text("+5h").multilineTextAlignment(.trailing).frame(alignment: .trailing)
          }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
          
          
        }
        StyledGroup {
          HStack {
            Text("Last 24 hours")
          }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
          if(activeEnergyLast2weeks?.sumQuantity != nil && activeEnergyLast24hours?.sumQuantity != nil){
            HStack {
              TrendArrow(value: activeEnergyLast24hours!.sumQuantity!, compareWith: activeEnergyLast2weeks!.sumQuantity! / 14)
              Text("Move").frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.leading)
              Text(activeEnergyLast24hours!.sumQuantity!.format(f: "1.0")).frame(minWidth: 0, maxWidth: cellWidth, alignment: Alignment.trailing)
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          }
          if(insulinLast24hours?.sumQuantity != nil && insulinLast2weeks?.sumQuantity != nil){
            HStack {
              TrendArrow(value: insulinLast24hours!.sumQuantity!, compareWith: insulinLast2weeks!.sumQuantity! / 14)
              Text("Insulin").frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
              Text(insulinLast24hours!.sumQuantity!.format(f: "1.0")).frame(minWidth: 0, maxWidth: cellWidth, alignment: Alignment.trailing)
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          }
        }.padding()
        StyledGroup {
          HStack {
            Text("Last 2 weeks")
          }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
          if(activeEnergyLast2weeks?.sumQuantity != nil && activeEnergyPrevious2weeks?.sumQuantity != nil){
            HStack {
              TrendArrow(value: activeEnergyLast2weeks!.sumQuantity!, compareWith: activeEnergyPrevious2weeks!.sumQuantity!)
              Text("Move").frame(minWidth: 0, maxWidth: .infinity, alignment: Alignment.leading)
              Text(activeEnergyLast2weeks!.sumQuantity!.format(f: "1.0")).frame(minWidth: 0, maxWidth: cellWidth, alignment: Alignment.trailing)
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          }
          if(insulinPrevious2weeks?.sumQuantity != nil && insulinLast2weeks?.sumQuantity != nil){
            HStack {
              TrendArrow(value: insulinLast2weeks!.sumQuantity!, compareWith: insulinPrevious2weeks!.sumQuantity!)
              Text("Insulin").frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
              Text(insulinLast2weeks!.sumQuantity!.format(f: "1.0")).frame(minWidth: 0, maxWidth: cellWidth, alignment: Alignment.trailing)
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          }
        }.padding()
      }.navigationBarTitle(LocalizedStringKey("active"))
    }
  }
}

struct ChartView_Previews: PreviewProvider {
  static var previews: some View {
    let optionalData = OptionalData()
    let last2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 111)
    let last24hours = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 111)
    return ChartView(activeInsulin: 5, chartWidth: Double(WKInterfaceDevice.current().screenBounds.width), chartHeight: 100, insulinLast2weeks: last2weeks, insulinLast24hours: last24hours,appState: AppState.current, optionalData: optionalData)
  }
}
