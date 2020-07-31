//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine
import HealthKit

class OptionalData: ObservableObject {
  @Published var chartImage: UIImage?
}


struct TrendArrow: View {
  var value: Double;
  var compareWith: Double;
  
  var body: some View {
    Image(systemName: value > compareWith * 2
      ? "arrow.up" : value > compareWith
      ? "arrow.up.right" : value == compareWith
      ? "arrow.right" : value * 2 < compareWith
      ? "arrow.down"
      : "arrow.down.right"
    )
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
  var isHealthKitAuthorized: HKAuthorizationRequestStatus?
  @State var isFocusable = true
  @ObservedObject var appState: AppState
  @ObservedObject var optionalData: OptionalData
  
  @ViewBuilder
  var body: some View {
    
    if(isHealthKitAuthorized == HKAuthorizationRequestStatus.unknown){
      Text(LocalizedString("please_authorize_read"))
    } else {
      ScrollView(){
        Group {if(insulinLast24hours?.sumQuantity == 0 || insulinLast24hours?.sumQuantity == nil){
          Button(action: {
            self.appState.activePage = .insulinInput
          }, label: {
              Text("Enter insulin")
            }).padding()
          } else {
            
          }
          
          Text(LocalizedString("insulin_on_board").uppercased()).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading).font(.system(size: 14)).foregroundColor(Color.gray)
          HStack(alignment: .center) {
            if(self.optionalData.chartImage != nil){
              Image(uiImage: self.optionalData.chartImage!)
            } else {
              
            }
          }.frame(maxWidth: CGFloat(chartWidth), minHeight: CGFloat(chartHeight), maxHeight: CGFloat(chartHeight), alignment: .center).background(Color.AlmosterBlack).cornerRadius(5)
          HStack(alignment: .top, spacing: 0) {
            Text("-1h").font(.system(size: 14)).foregroundColor(Color.gray)
            Text("\(activeInsulin.format("0.1"))").multilineTextAlignment(.center).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).foregroundColor(Color(UIColor.magenta))
            Text("+5h").multilineTextAlignment(.trailing).frame(alignment: .trailing)
          }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14)).foregroundColor(Color.gray)
          
        }
        
        if(insulinLast24hours?.sumQuantity != nil && insulinLast2weeks?.sumQuantity != nil){
          Divider()
          HStack {
            Text(LocalizedString("units_of_insulin").uppercased()).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading).foregroundColor(Color.gray).font(.system(size: 14))
          }
          
          HStack {
            Text(insulinLast24hours!.sumQuantity!.format("1.0")).foregroundColor(Color.AccentColor)
            Text( LocalizedString("past_24h") ).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing).foregroundColor(Color.gray).font(.system(size: 14))
          }
          HStack {
            Text(insulinLast2weeks!.sumQuantity!.format("1.0")).foregroundColor(Color.AccentColor)
            Text( LocalizedString("past_2_weeks") ).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing).foregroundColor(Color.gray).font(.system(size: 14))
          }
        }
        
        if(activeEnergyLast2weeks?.sumQuantity != nil && activeEnergyLast24hours?.sumQuantity != nil && activeEnergyLast24hours?.sumQuantity != 0){
          Divider()
          HStack {
            Text( LocalizedString("activity").uppercased()).foregroundColor(Color.gray).font(.system(size: 14))
            Text(LocalizedString("past_24h").uppercased()).foregroundColor(Color.gray).font(.system(size: 14)).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
          }
          
          
          HStack {
            TrendArrow(value: activeEnergyLast24hours!.sumQuantity!, compareWith: activeEnergyLast2weeks!.sumQuantity! / 14).foregroundColor(activeEnergyLast24hours!.sumQuantity! > (activeEnergyLast2weeks!.sumQuantity! / 14) ? Color.green : activeEnergyLast24hours!.sumQuantity! < (activeEnergyLast2weeks!.sumQuantity! / 14) ? Color.red : Color.white)
            Text(
                (
                  Double(
                    100 * activeEnergyLast24hours!.sumQuantity! / (activeEnergyLast2weeks!.sumQuantity! / 14)) - 100
                ).format("1.0") + "%"
              )
              .foregroundColor(Color.green)
              .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(activeEnergyLast24hours!.sumQuantity!.format("1.0") + " kcal")
            
          }
          Text("compared_to_the_past_2_weeks").multilineTextAlignment(.center).lineLimit(nil).foregroundColor(Color.gray).font(.system(size: 12))
        }
        
        
      }.navigationBarTitle(LocalizedStringKey("stats"))
    }
  }
}

struct ChartView_Previews: PreviewProvider {
  static var previews: some View {
    let optionalData = OptionalData()
    let last2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 2311)
    let previous2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 1111)
    let last24hours = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 111)
    
    let energyLast2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 5000)
    let energyPrevious2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 4000)
    let energyLast24hours = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 400)
    return ChartView(activeInsulin: 5, chartWidth: Double(WKInterfaceDevice.current().screenBounds.width), chartHeight: 100, insulinLast2weeks: last2weeks, insulinLast24hours: last24hours, insulinPrevious2weeks: previous2weeks, activeEnergyLast2weeks: energyLast2weeks, activeEnergyPrevious2weeks: energyPrevious2weeks, activeEnergyLast24hours: energyLast24hours,appState: AppState(), optionalData: optionalData)
  }
}
