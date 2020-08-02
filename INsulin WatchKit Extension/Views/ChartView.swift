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
    ).foregroundColor(value > compareWith ? Color.green : value < compareWith ? Color.red : Color.white)
  }
}

struct ChartView: View {
   @State private var showingAlert = false
  var insulinOnBoard: Double
  var chartWidth: Double
  var chartHeight: Double
  var isHealthKitAuthorized: HKAuthorizationRequestStatus?
  var activeEnergyLast2Weeks: Double;
  var activeEnergyLast24Hours: Double;
  var insulinUnitsLast2Weeks: Double;
  var insulinUnitsLast24Hours: Double;
  @ObservedObject var appState: AppState
  @ObservedObject var optionalData: OptionalData
  
  @ViewBuilder
  var body: some View {
    
    if(isHealthKitAuthorized == HKAuthorizationRequestStatus.unknown){
      Text(LocalizedString("please_authorize_read"))
    } else {
      ScrollView(){
        Group {if(insulinUnitsLast24Hours == 0){
          Button(action: {
            self.appState.activePage = .insulinInput
          }, label: {
              Text("Enter insulin")
            }).padding()
          } else {
            
          }
          
          VStack {
            HStack {
              Text(LocalizedString("insulin_on_board").uppercased()).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading).font(.system(size: 14)).foregroundColor(Color.gray)
              Image(systemName: "info.circle.fill").foregroundColor(Color.gray)
            }
            HStack(alignment: .center) {
              if(self.optionalData.chartImage != nil){
                Image(uiImage: self.optionalData.chartImage!)
              } else {
                
              }
            }.frame(maxWidth: CGFloat(chartWidth), minHeight: CGFloat(chartHeight), maxHeight: CGFloat(chartHeight), alignment: .center)
              .background(Color.AlmosterBlack).cornerRadius(5)
            
          }.accentColor(Color.black).onTapGesture {
            self.showingAlert = true;
          }.alert(isPresented: $showingAlert,  content: {
            Alert(title: Text("insulin_on_board"), message: Text("iob_info_text"))
          })
          
          
          HStack(alignment: .top, spacing: 0) {
            Text("-1h").font(.system(size: 14)).foregroundColor(Color.gray)
            Text("\(insulinOnBoard.format("0.1"))").multilineTextAlignment(.center).frame(minWidth: 0, maxWidth: .infinity, alignment: .center).foregroundColor(Color(UIColor.magenta))
            Text("+5h").multilineTextAlignment(.trailing).frame(alignment: .trailing)
          }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14)).foregroundColor(Color.gray)
          
        }
        
        if(insulinUnitsLast24Hours > 0 && insulinUnitsLast2Weeks > 0){
          Divider()
          HStack {
            Text(LocalizedString("units_of_insulin").uppercased()).frame(minWidth: 0, maxWidth: .infinity, alignment: .leading).foregroundColor(Color.gray).font(.system(size: 14))
          }
          
          HStack {
            Text(insulinUnitsLast24Hours.format("1.0")).foregroundColor(Color.AccentColor)
            Text( LocalizedString("past_24h") ).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing).foregroundColor(Color.gray).font(.system(size: 14))
          }
          HStack {
            Text(insulinUnitsLast2Weeks.format("1.0")).foregroundColor(Color.AccentColor)
            Text( LocalizedString("past_2_weeks") ).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing).foregroundColor(Color.gray).font(.system(size: 14))
          }
        }
        
        if(activeEnergyLast2Weeks > 0 && activeEnergyLast24Hours > 0){
          Divider()
          HStack {
            Text( LocalizedString("activity").uppercased()).foregroundColor(Color.gray).font(.system(size: 14))
            Text(LocalizedString("past_24h").uppercased()).foregroundColor(Color.gray).font(.system(size: 14)).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
          }
          
          
          HStack {
            TrendArrow(value: activeEnergyLast24Hours, compareWith: activeEnergyLast2Weeks / 14)
            Text(
                (
                  Double(
                    100 * activeEnergyLast24Hours / (activeEnergyLast2Weeks / 14)) - 100
                ).format("1.0") + "%"
              )
              .foregroundColor(Color.green)
              .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text(activeEnergyLast24Hours.format("1.0") + " kcal")
            
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
    /*let last2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 2311)
    let previous2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 1111)
    let last24hours = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 111)
    
    let energyLast2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 5000)
    let energyPrevious2weeks = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 4000)
    let energyLast24hours = StatsResponse(/*maximumQuantity: 11, minimumQuantity: 1,*/ mostRecentQuantity: 10, mostRecentTime: Date(), sumQuantity: 400)*/
    
    return ChartView(insulinOnBoard: 5, chartWidth: Double(WKInterfaceDevice.current().screenBounds.width), chartHeight: 100, isHealthKitAuthorized: .unnecessary, activeEnergyLast2Weeks: 280, activeEnergyLast24Hours: 500, insulinUnitsLast2Weeks: 6900, insulinUnitsLast24Hours: 20, appState: AppState.current, optionalData: optionalData)
  }
}
