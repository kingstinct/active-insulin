//
//  InjectionView.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-08-13.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI

struct InjectionView: View {
  var delete: () -> Void
  
  var injection: Injection
    let dateFormatter: DateFormatter
    @ViewBuilder
    var body: some View {
      VStack {
        Text(dateFormatter.string(from: injection.date)).font(.system(size: 14)).foregroundColor(Color.gray).frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        Text(injection.insulinUnits.format("0.1")).foregroundColor(Color.AccentColor).font(.system(size: 30))
        Button(action: {
          self.delete();
        }, label: {
          Text(LocalizedStringKey(stringLiteral: "Delete"));
        }).accentColor(Color.red).frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
      }
    }
}

struct InjectionView_Previews: PreviewProvider {
    static var previews: some View {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm"
      
      let injection = Injection(date: Date(), insulinUnits: 0.5)
      return InjectionView(delete: {
        
      }, injection: injection, dateFormatter: formatter)
    }
}
